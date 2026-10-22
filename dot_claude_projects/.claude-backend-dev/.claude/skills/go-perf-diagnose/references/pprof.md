# pprof 速查

## 接入

`import _ "net/http/pprof"` 把 `/debug/pprof/*` 注册到 `http.DefaultServeMux`。业务使用 Fiber、Gin 等自己的路由时，单独起诊断端口，不挂到业务路由：

```go
go func() {
	// 只监听 localhost 或内网地址；由配置开关控制，生产默认关闭，经 SSH 隧道访问
	if err := http.ListenAndServe("127.0.0.1:6060", nil); err != nil {
		logger.Error("pprof server", "err", err)
	}
}()
```

block 与 mutex profile 默认关闭，不设置采样率只会得到空 profile：

```go
runtime.SetBlockProfileRate(rate)       // 每阻塞约 rate 纳秒采一次；1 = 全部记录
runtime.SetMutexProfileFraction(frac)   // 约 1/frac 的锁竞争事件；1 = 全部记录
```

排查时临时设为 1；常开时取较大的值（值越大采样越少、开销越低），按实测开销调整。

生产环境：诊断端口只绑 `localhost` 或内网，远程经 SSH 隧道或带鉴权的内网网关访问（profile 暴露函数名与调用关系）；CPU profile 采集期间约有 5% 的额外开销，高峰期选单个实例采集；trace 开销更大，只短时开启。

## 采集

```sh
P=http://127.0.0.1:6060/debug/pprof
curl -o cpu.prof   "$P/profile?seconds=30"   # 采集期间要有负载，至少 10 秒
curl -o heap.prof  "$P/heap"
curl -o block.prof "$P/block"
curl -o mutex.prof "$P/mutex"
curl "$P/goroutine?debug=1"                   # 按相同栈聚合计数，适合看泄漏
curl "$P/goroutine?debug=2"                   # 每个 goroutine 的完整栈与等待时长
```

先存文件再分析，便于修改后对比。benchmark 也可直接产出：`go test -bench=X -cpuprofile cpu.prof -memprofile mem.prof`。

## 分析

```sh
go tool pprof -top -cum cpu.prof          # 先看 cum，找第一个业务函数
go tool pprof -list 'pkg.Func' cpu.prof   # 精确到行
go tool pprof -peek 'pkg.Func' cpu.prof   # 调用方与被调用方
go tool pprof -http=:8081 cpu.prof        # 火焰图：找宽的，不是找高的
go tool pprof -sample_index=alloc_objects -top heap.prof
go tool pprof -base old.prof new.prof     # 差值，验证修复或找增长
```

| heap 口径 | 用途 |
|---|---|
| `inuse_space`（默认） | 常驻内存、泄漏 |
| `inuse_objects` | 常驻的小对象过多 |
| `alloc_space` / `alloc_objects` | 历史累计分配，GC 压力 |

heap profile 默认约每 512KB 分配采样一次，小对象数为估算值。

block 与 mutex 视角不同：block 记录等待方（`Mutex.Lock`、channel、`WaitGroup.Wait`），mutex 把等待时间记在释放锁的位置（`Unlock`）。先看 block 确定等在哪，是锁再看 mutex 找持有者。

## 内存指标

| `runtime.MemStats` | 含义 |
|---|---|
| `HeapAlloc` | 存活对象，GC 后下降 |
| `HeapInuse` | 堆占用的 span，含碎片 |
| `HeapReleased` | 已归还操作系统 |
| `Sys` | 向操作系统申请的总量，接近但不等于 RSS |

GC 回收后内存由后台逐步归还系统，RSS 下降滞后于 `HeapAlloc`。`debug.FreeOSMemory()` 会触发一次完整 GC，不在生产路径上调用。`GOMEMLIMIT` 是软上限，cgo 分配的内存不计入。
