package main

import (
	"flag"
	"fmt"
	"os"
	"os/exec"
	"os/signal"
	"strings"
	"syscall"
	"time"
)

func format_short(d time.Duration) string {
	hours := d / time.Hour
	minutes := (d % time.Hour) / time.Minute

	if hours > 0 {
		return fmt.Sprintf("%dh%dm", hours, minutes)
	}

	return fmt.Sprintf("%dm", minutes)
}

func notify_time(dur time.Duration, long bool) {
	dstr := dur.String()

	if !long {
		dstr = format_short(dur)
	}

	fmt.Println("📖", dstr)
}

func notify_clear() {
	fmt.Println("💤")
}

func notify_os(arg string) {
	go exec.Command("notify-send", arg).Run()
}

func clock(poller <-chan time.Duration, died <-chan bool, done <-chan bool) {
	ticker := time.NewTicker(1 * time.Second)
	defer ticker.Stop()
	alive := false
	current_time := 0 * time.Second

	long := true
	hours_crossed := 0

	sigusr2 := make(chan os.Signal, 1)
	signal.Notify(sigusr2, syscall.SIGUSR2)

	for {
		select {
		case t := <-poller:
			alive = true
			current_time = t
		case <-died:
			alive = false
			hours_crossed = 0
			notify_clear()
		case <-ticker.C:
			if alive {
				current_time += 1 * time.Second

				curr_hours := int(current_time.Hours())
				if curr_hours > hours_crossed {
					hours_crossed = curr_hours
					s := fmt.Sprintf("🎉 %d WHOLE hours of GRIND! LEZGO 🎉", hours_crossed)
					notify_os(s)
				}

				notify_time(current_time, long)
			}
		case <-sigusr2:
			long = !long
		case <-done:
			return
		}
	}
}

func parseFlexibleDuration(s string) (time.Duration, error) {
	parts := strings.Split(s, ":")
	var h, m, sec int

	switch len(parts) {
	case 1:
		_, err := fmt.Sscanf(parts[0], "%d", &sec)
		return time.Duration(sec) * time.Second, err
	case 2:
		_, err := fmt.Sscanf(s, "%d:%d", &m, &sec)
		return time.Duration(m)*time.Minute +
			time.Duration(sec)*time.Second, err
	case 3:
		_, err := fmt.Sscanf(s, "%d:%d:%d", &h, &m, &sec)
		return time.Duration(h)*time.Hour +
			time.Duration(m)*time.Minute +
			time.Duration(sec)*time.Second, err
	default:
		return 0, fmt.Errorf("invalid duration format")
	}
}

func poll() (time.Duration, error) {
	// cmd := exec.Command("bash", "-c", `
	// 	swaymsg -t get_tree | jq -r '
	// 	  first(recurse(.nodes[]?, .floating_nodes[]?)
	// 	    | select(.app_id == "firefox")
	// 	    | select(.name | test(".* • Clockify — Mozilla Firefox"))
	// 	    | .name
	// 	    ) // error("No clockify instances")'
	// `)

	cmd := exec.Command("bash", "-c", `
		niri msg -j windows | jq ' .[] 
		   | select(.title | test(".* • Clockify — Mozilla Firefox")) 
		   | .title // error("No clockify instances")' 
	`)

	out, err := cmd.Output()

	if err != nil {
		return 0, err
	}

	string_out := strings.Trim(string(out), `"`)

	return parseFlexibleDuration(string_out)
}

func poller(poll_interval time.Duration, done, force <-chan bool) (<-chan time.Duration, <-chan bool) {
	ticker := time.NewTicker(poll_interval)
	died := make(chan bool)
	poller := make(chan time.Duration)

	sigs := make(chan os.Signal, 1)
	signal.Notify(sigs, syscall.SIGUSR1)

	go func() {
		defer ticker.Stop()

		poll_and_notify := func() {
			out, err := poll()

			if err != nil {
				died <- true
			} else {
				poller <- out
			}
		}

		for {
			select {
			case <-force:
				poll_and_notify()
			case <-sigs:
				poll_and_notify()
			case <-ticker.C:
				poll_and_notify()
			case <-done:
				return
			}
		}
	}()

	return poller, died
}

func main() {
	poll_interval := flag.Duration("poll-interval", 15*time.Second,
		"The interval at which to poll sway")

	done := make(chan bool)
	force := make(chan bool)
	poller, died := poller(*poll_interval, done, force)
	force <- true
	clock(poller, died, done)
}
