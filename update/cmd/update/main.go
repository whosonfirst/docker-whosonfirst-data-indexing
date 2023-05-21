package main

import (
	"context"

	"github.com/aws/aws-lambda-go/lambda"
	"github.com/sfomuseum/go-flags/flagset"
	"github.com/aaronland/go-aws-ecs"
	"github.com/whosonfirst/go-whosonfirst-github/organizations"
	"github.com/sfomuseum/iso8601duration"	
)

func main() {

	var mode string
	var github_org string
	var aws_session_uri string
	
	fs := flagset.NewFlagSet("update")

	fs.StringVar(&mode, "mode", "cli", "")
	fs.StringVar(&github_org, "github-organization", "whosonfirst-data", "")
	fs.StringVar(&aws_session_uri, "aws-session-uri", "")
	
	flagset.Parse(fs)

	
	svc, err := ecs.NewService(aws_session_uri)

	if err != nil {
		log.Fatalf("Failed to create new service, %v", err)
	}

	task_opts := &ecs.TaskOptions{
		Task:            *task,
		Container:       *container,
		Cluster:         *cluster,
		LaunchType:      *launch_type,
		PlatformVersion: *platform_version,
		PublicIP:        *public_ip,
		Subnets:         subnets,
		SecurityGroups:  security_groups,
	}

	list_opts := organizations.NewDefaultListOptions()

	updateFunc := func(ctx context.Context) error {

		repos, err := organizations.ListRepos(github_org, list_opts)
		if err != nil {
			return fmt.Errorf("Failed to list repos for %s, %w", github_org, err)
		}
		
		for _, name := range repos {


			cmd := []string{
				name,
			}
			
			_, err := ecs.LaunchTask(ctx, svc, task_opts, cmd...)

			if err != nil {
				return fmt.Errorf("Failed to launch ECS task for %s, %w", name, err)
			}
		}

		return nil
	}

	switch mode {
	case "cli":

		err := updateFunc(ctx)

		if err != nil {
			log.Fatalf("Failed to perform updates, %w", err)
		}
		
	case "lambda":

		lamba.Start(updateFunc)
		
	default:
		log.Fatalf("Invalid mode '%s'", mode)
	}
}

