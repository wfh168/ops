# 1. 停止所有正在运行的容器
```
docker stop $(docker ps -aq)
```



# 2. 删除所有容器
```
docker rm $(docker ps -aq)
```

# 3. 删除所有未被使用的网络（包括自定义 bridge）
```
docker network prune -f
```



# 4. 删除所有未被使用的 volume（⚠️ 这会清除 MySQL/Redis 等持久化数据！）
```
docker volume prune -f
```



# 5. 删除所有镜像（包括中间件如 mysql, redis, zookeeper, kafka）
```
docker rmi $(docker images -q) -f
```



# 6. 清理构建缓存、悬挂资源等
```
docker system prune -af --volumes
```

