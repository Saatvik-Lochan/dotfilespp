package main

import (
    "fmt"
    "os"
    "os/exec"
    "os/signal"
    "syscall"
    "time"
    "strings"
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

func clock(poller <-chan time.Duration, died <-chan bool, done <-chan bool) {
	ticker := time.NewTicker(1 * time.Second)
	defer ticker.Stop()
	alive := false
	current_time := 0 * time.Second

	long := true

        sigusr2 := make(chan os.Signal, 1)
        signal.Notify(sigusr2, syscall.SIGUSR2)

	for {
		select {
		case t := <-poller:
			alive = true
			current_time = t
		case <-died:
			alive = false
			notify_clear()
		case <-ticker.C:
			if alive {
				current_time += 1 * time.Second
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
	cmd := exec.Command("bash", "-c", `
		swaymsg -t get_tree | jq -r '
		  first(recurse(.nodes[]?, .floating_nodes[]?) 
		    | select(.app_id == "firefox") 
		    | select(.name | test(".* • Clockify — Mozilla Firefox"))
		    | .name
		    ) // error("No clockify instances")'
	`)

	out, err := cmd.Output()

	if err != nil {
		return 0, err
	}

	return parseFlexibleDuration(string(out))
}

func poller(done <-chan bool) (<-chan time.Duration, <-chan bool) {
	ticker := time.NewTicker(15 * time.Second) 
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
	done := make(chan bool)
	poller, died := poller(done)
	clock(poller, died, done)
}
