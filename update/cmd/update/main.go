package main

import (
	"context"
	"fmt"
	"log"
	"time"
	
	"github.com/aaronland/go-aws-ecs"
	"github.com/aws/aws-lambda-go/lambda"
	"github.com/sfomuseum/go-flags/flagset"
	"github.com/sfomuseum/go-flags/multi"
	"github.com/sfomuseum/iso8601duration"
	"github.com/whosonfirst/go-whosonfirst-github/organizations"
)

func main() {

	var mode string
	var github_org string
	var aws_session_uri string

	var ecs_task string
	var ecs_container string
	var ecs_cluster string
	var ecs_launch_type string
	var ecs_platform string
	var ecs_public_ip string

	var ecs_subnets multi.MultiString
	var ecs_security_groups multi.MultiString

	var updated_since string
	
	fs := flagset.NewFlagSet("update")

	fs.StringVar(&mode, "mode", "cli", "")
	fs.StringVar(&github_org, "github-organization", "whosonfirst-data", "")
	fs.StringVar(&aws_session_uri, "aws-session-uri", "", "")

	fs.StringVar(&ecs_task, "ecs-task", "", "The name (and version) of your ECS task.")
	fs.StringVar(&ecs_container, "ecs-container", "", "The name of your ECS container.")
	fs.StringVar(&ecs_cluster, "ecs-cluster", "", "The name of your ECS cluster.")
	fs.StringVar(&ecs_launch_type, "ecs-launch-type", "", "A valid ECS launch type.")
	fs.StringVar(&ecs_platform, "ecs-platform-version", "", "A valid ECS platform version.")
	fs.StringVar(&ecs_public_ip, "ecs-public-ip", "", "A valid ECS public IP string.")

	fs.Var(&ecs_subnets, "ecs-subnet", "One or more subnets to run your ECS task in.")
	fs.Var(&ecs_security_groups, "ecs-security-group", "A valid AWS security group to run your task under.")

	fs.StringVar(&updated_since, "updated-since", "", "")
	
	flagset.Parse(fs)

	d, err := duration.FromString(updated_since)
	
	if err != nil {
		log.Fatalf("Failed to parse '%s', %w", updated_since, err)
	}
	
	now := time.Now()
	since := now.Add(-d.ToDuration())

	svc, err := ecs.NewService(aws_session_uri)

	if err != nil {
		log.Fatalf("Failed to create new service, %v", err)
	}

	task_opts := &ecs.TaskOptions{
		Task:            ecs_task,
		Container:       ecs_container,
		Cluster:         ecs_cluster,
		LaunchType:      ecs_launch_type,
		PlatformVersion: ecs_platform,
		PublicIP:        ecs_public_ip,
		Subnets:         ecs_subnets,
		SecurityGroups:  ecs_security_groups,
	}

	list_opts := organizations.NewDefaultListOptions()
	// list_opts.Prefix = "whosonfirst-data"
	list_opts.PushedSince = &since

	updateFunc := func(ctx context.Context) error {

		repos, err := organizations.ListRepos(github_org, list_opts)

		if err != nil {
			return fmt.Errorf("Failed to list repos for %s, %w", github_org, err)
		}

		for _, name := range repos {

			task_cmd := []string{
				"/usr/local/bin/index.sh",
				"-R",
				"-r",
				name,
			}

			_, err := ecs.LaunchTask(ctx, svc, task_opts, task_cmd...)

			if err != nil {
				return fmt.Errorf("Failed to launch ECS task for %s, %w", name, err)
			}
		}

		return nil
	}

	switch mode {
	case "cli":

		ctx := context.Background()
		err := updateFunc(ctx)

		if err != nil {
			log.Fatalf("Failed to perform updates, %w", err)
		}

	case "lambda":

		lambda.Start(updateFunc)

	default:
		log.Fatalf("Invalid mode '%s'", mode)
	}
}
