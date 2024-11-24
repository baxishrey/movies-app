[{
"name": "${app_name}",
"image": "${app_image}",
"cpu": ${fargate_cpu},
"memory": ${fargate_memory},
"networkMode": "awsvpc",
"logConfiguration": {
    "logDriver": "awslogs",
    "options": {
        "awslogs-group": "/ecs/${app_name}",
        "awslogs-region": "${aws_region}",
        "awslogs-stream-prefix": "${app_name}"
    }
},
"environment": [
    {
        "name": "MONGODB_URL",
        "value": "mongodb.movie-app"
    },
    {
        "name": "REACT_APP_API_URL",
        "value": "${backend_app_url}"
    }
],
"portMappings": ${port_mappings}
}
]