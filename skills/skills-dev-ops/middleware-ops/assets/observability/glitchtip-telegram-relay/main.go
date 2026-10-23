// glitchtip-telegram-relay 把 GlitchTip 的 Slack 兼容 webhook 转发到 Telegram Bot API。
package main

import (
	"bytes"
	"context"
	"crypto/subtle"
	"encoding/json"
	"fmt"
	"html"
	"log/slog"
	"net/http"
	"os"
	"strings"
	"time"
)

type payload struct {
	Text        string `json:"text"`
	Attachments []struct {
		Title     string `json:"title"`
		TitleLink string `json:"title_link"`
		Text      string `json:"text"`
		Fields    []struct {
			Title string `json:"title"`
			Value string `json:"value"`
		} `json:"fields"`
	} `json:"attachments"`
}

func main() {
	var (
		apiURL = getenv("TELEGRAM_API_URL", "https://api.telegram.org")
		token  = mustenv("TELEGRAM_BOT_TOKEN")
		chatID = mustenv("TELEGRAM_CHAT_ID")
		secret = mustenv("RELAY_SECRET") // webhook URL 中的路径段，防止被他人调用
	)
	client := &http.Client{Timeout: 10 * time.Second}
	mux := http.NewServeMux()
	mux.HandleFunc("GET /healthz", func(w http.ResponseWriter, _ *http.Request) { w.WriteHeader(http.StatusOK) })
	mux.HandleFunc("POST /glitchtip/{secret}", func(w http.ResponseWriter, r *http.Request) {
		if subtle.ConstantTimeCompare([]byte(r.PathValue("secret")), []byte(secret)) != 1 {
			http.NotFound(w, r)
			return
		}
		var p payload
		if err := json.NewDecoder(http.MaxBytesReader(w, r.Body, 1<<20)).Decode(&p); err != nil {
			http.Error(w, "bad payload", http.StatusBadRequest)
			return
		}
		body, _ := json.Marshal(map[string]any{
			"chat_id":                  chatID,
			"text":                     format(p),
			"parse_mode":               "HTML",
			"disable_web_page_preview": true,
		})
		ctx, cancel := context.WithTimeout(r.Context(), 10*time.Second)
		defer cancel()
		req, _ := http.NewRequestWithContext(ctx, http.MethodPost, apiURL+"/bot"+token+"/sendMessage", bytes.NewReader(body))
		req.Header.Set("Content-Type", "application/json")
		resp, err := client.Do(req)
		if err != nil {
			slog.Error("send to telegram", "err", err)
			http.Error(w, "upstream error", http.StatusBadGateway)
			return
		}
		defer resp.Body.Close()
		if resp.StatusCode != http.StatusOK {
			slog.Error("telegram rejected message", "status", resp.StatusCode)
			http.Error(w, "upstream rejected", http.StatusBadGateway)
			return
		}
		w.WriteHeader(http.StatusNoContent)
	})
	srv := &http.Server{Addr: ":8080", Handler: mux, ReadHeaderTimeout: 5 * time.Second}
	slog.Info("relay listening", "addr", srv.Addr)
	if err := srv.ListenAndServe(); err != nil {
		slog.Error("server stopped", "err", err)
		os.Exit(1)
	}
}

// format 生成 Telegram HTML 消息；Telegram 单条消息上限 4096 字符。
func format(p payload) string {
	var b strings.Builder
	fmt.Fprintf(&b, "<b>%s</b>\n", html.EscapeString(p.Text))
	for _, a := range p.Attachments {
		fmt.Fprintf(&b, "\n<a href=\"%s\">%s</a>\n", html.EscapeString(a.TitleLink), html.EscapeString(a.Title))
		if a.Text != "" {
			fmt.Fprintf(&b, "<code>%s</code>\n", html.EscapeString(a.Text))
		}
		for _, f := range a.Fields {
			fmt.Fprintf(&b, "%s: %s\n", html.EscapeString(f.Title), html.EscapeString(f.Value))
		}
	}
	s := b.String()
	if r := []rune(s); len(r) > 4000 {
		s = string(r[:4000]) + "…"
	}
	return s
}

func getenv(k, def string) string {
	if v := os.Getenv(k); v != "" {
		return v
	}
	return def
}

func mustenv(k string) string {
	v := os.Getenv(k)
	if v == "" {
		slog.Error("missing env", "key", k)
		os.Exit(1)
	}
	return v
}
