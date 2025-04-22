package main

import (
	"encoding/json"
	"log"
	"net/http"

	"github.com/shirou/gopsutil/cpu"
	"github.com/shirou/gopsutil/host"
	"github.com/shirou/gopsutil/mem"
)

type Stats struct {
	Hostname string `json:"hostname"`
	Platform string `json:"platform"`
	CPU      string `json:"cpu"`
	Memory   uint64 `json:"memory"`
}

func getDetails(w http.ResponseWriter, r *http.Request) {
	hostStat, _ := host.Info()
	cpuStat, _ := cpu.Info()
	vmStat, _ := mem.VirtualMemory()

	json.NewEncoder(w).Encode(Stats{
		Hostname: hostStat.Hostname,
		Platform: hostStat.Platform,
		CPU:      cpuStat[0].VendorID,
		Memory:   vmStat.Total / 1024 / 1024,
	})
}

func main() {
	r := http.NewServeMux()
	r.HandleFunc("GET /info", http.HandlerFunc(getDetails))

	log.Fatal(http.ListenAndServe(":8080", r))
}
