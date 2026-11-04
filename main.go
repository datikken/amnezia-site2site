package main

import (
	"fmt"
	"os"
	"os/exec"
)

func main() {
	if err := run(os.Args[1:]); err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}
}

func run(args []string) error {
	if len(args) == 0 {
		fmt.Println("Hello, World!")
		return nil
	}

	if len(args) != 1 || args[0] != "admin-setup" {
		return fmt.Errorf("usage: %s [admin-setup]", os.Args[0])
	}

	if err := os.MkdirAll("admin/app", 0755); err != nil {
		return fmt.Errorf("create admin application directory: %w", err)
	}

	if err := runDockerCompose("run", "--build", "--rm", "app", "sh", "/usr/local/bin/admin-bootstrap"); err != nil {
		return fmt.Errorf("bootstrap Laravel and Filament: %w", err)
	}
	if err := runDockerCompose("up", "-d"); err != nil {
		return fmt.Errorf("start admin containers: %w", err)
	}

	fmt.Println("Admin panel is available at http://localhost:8080/admin")
	return nil
}

func runDockerCompose(args ...string) error {
	composeArgs := append([]string{"compose", "-f", "admin/docker-compose.yml"}, args...)
	cmd := exec.Command("docker", composeArgs...)
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	cmd.Stdin = os.Stdin
	return cmd.Run()
}
