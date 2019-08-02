同一个Pod内的多个容器间： lo通信
各Pod之间的通信

k8s三个核心： Pod   Service  控制器
master三个核心组件： Apiserver  ControllerManger  Scheduler(负责Pod调度)


-----------------------------------------------------------------------------------------------------------------------------
四层负载均衡（调度）： 把客户端请求访问的IP地址和端口，修改为集群内部的IP地址和端口来访问 LVs
七层负载均衡（调度）： 在四层调度之上，再修改访问请求里面的一些具体信息，比如图片，url，数据库等，更智能化 Nginx,Haproxy

OSI七层模型：
    ┌───────┐
    │ 应用层   │←第七层     应用程序间通讯                 HTTP TFTP FTP NFS WAIS SMTP
　  ├───────┤
　  │ 表示层   │           处理数据格式，数据加密等         Telnet Rlogin  SNMP Gopher     
　  ├───────┤
    │ 会话层  │            建立，维护，和管理会话          SMTP  DNS 
　　├───────┤
　　│　传输层  │            建立主机端到端连接             TCP UDP  四层交换机，四层路由器
　　├───────┤
　　│　网络层  │            寻找和路由选择                 IP ICMP ARP RARP AKP UUCP 路由器，三层交换机
　　├───────┤
　　│数据链路层│            提供介质访问，链路管理等        FDDI PDN  PPP 网桥，以太网交换机，网卡
　　├───────┤
　　│　物理层  │←第一层      比特流传输                    IEEE 802.1A  IEEE802.2到IEEE 802.11 中继器，双绞线
　　└───────┘ 
OSI四层模型：
    ┌─────────┐
    │ 应用层  │      
　  │         │
　  │ 表示层  │                 
    │　       │
    │ 会话层  │            
　　├─────────┤
　　│　传输层            
　　├─────────┤
　　│　网络层            
　　├─────────┤
　　│数据链路层│            
　　│         │
　　│　物理层  │  ←第一层      
　　└─────────┘ 
---------------------------------------------------------------------------------------------------------------------------------

yaml文件里 举例：  volumes    <[]Object>  说明这个是对象列表   那么在写的时候就是
    volemes:
    - name: test


kubectl cluster-info
kubectl run --help
kubectl命令： create（创建） get（查看） edit（编辑） delete（删除） rollout（回滚） scale（手动改变应用程序的规模） autoscale（自动改变应用程序的规模） 
		     certificate（证书） cluster-info（集群信息） top（类似linux 的top） cordon（标记节点不可被调用） uncordon（标记节点可被调用）
			 taint（给节点增加污点）describe（描述资源的详细信息） logs（日志） attach（类似docker的attach） exec（类似docker的exec） 
			 port-forward（端口转发） proxy（代理） cp（在容器之间，跨容器复制文件的） auth（测试认证）
			 apply（创建修改） patch（打补丁） replace（替换） wait（等待定义触发器） convert（转换）
			 label（打标签） annotate（注解） completion（命令补全）
kubectl version # 看各种版本号 
kubectl cluster-info # 查看集群信息


kubectl run nginx --image=nginx 
--replicas=5 		#启动5个nginx 
--restart=Never		#任何容器结束不会自动补上去（默认是自动补上去的）
--commadn  			#自定义命令 例如 /bin/sh
--port 				#指定要暴露哪个端口
--dry-run=true		#干跑模式
-it 				#交互式连入控制台  类似docker的 -it


示例：kubectl run nginx-deploy --image=nginx:1.14-alpine  --port=80 --replicas=1

kubectl get pods -o wide
kubectl get deployment		#查看当前已经创建的deployment

kubectl expose --help		#创建暴露servicce IP和端口 的命令

kubectl expose deployment nginx-deploy --name=nginx  --port=80 --target-port=80   
#给nginx这个pod做了一个不变的统一的IP地址，访问这个IP地址是不变的

kubectl get service -n kube-system		#查看kube的dns名字和地址
kubectl get pods --show-labels			#查看pod的标签
yum -y install bind-utils
dig -t A nginx.deafult.svc.cluster.local @10.96.0.10		#域名解析

kubectl run myapp --image=ikubernetes/myapp:v1 --replicas=2		#创建一个名字叫myapp的deployment
kubectl expose deployment myapp  --name=myapp1 --port=80
	wget -O - -q myapp1	  #就直接访问myapp
kubectl scale --replicas=5 deployment myapp   #动态扩展或者缩减到5个nginx
kubectl edit rs myapp 
	spec: replicas 5	#动态修改pod数量为5个，可多可少

kubectl set image deployment myapp myapp=ikubernetes/myapp:v2	#升级容器版本v1变成v2，指明容器的镜像版本号为v2
kubectl rollout status deployment myapp 		#查看升级的状态   rollout回滚
kubectl rollout undo deployment myapp 			#回滚版本，从v2回滚到v1

#设置集群外通过物理机IP访问集群内的myapp
kubectl edit svc myapp1
	type: NodePort		#原来是ClusterIP

#再用 kubectl get svc 查看对应的端口号	然后就可以直接访问了  http://192.168.188.135:30405/

kubectl get pod myapp-5bc569c47d-k5hxp -o yaml		#这个pod的信息输出为yaml格式显示

kubectl get deployment
	NAME           READY   UP-TO-DATE   AVAILABLE   AGE
	myapp          3/3     3            3           22h
	nginx-deploy   1/1     1            1           28h

kubectl get pods
	NAME                           READY   STATUS    RESTARTS   AGE
	client                         1/1     Running   0          21h
	myapp-5bc569c47d-8fbq5         1/1     Running   0          21h
	myapp-5bc569c47d-k5hxp         1/1     Running   0          21h
	myapp-5bc569c47d-rmlfs         1/1     Running   0          21h
	nginx-deploy-55d8d67cf-dkj8j   1/1     Running   0          27h
	pod-demo                       2/2     Running   0          13m

可以看出，deployment是pods的控制器，一个deployment可以有好多个pods

####################################################################################################

资源：对象
	workload： Pod,PeplicaSet,Deployment,StatefulSet,DaemonSet,Job,Cronjob...
	服务发现及均衡：service，Ingress,...
	配置与存储：Volume，CSI
		ConfigMap,Secret
		DownwardAPI
	集群级资源
		Namespace,Node,Role,ClusterRole,RoleBinding,ClusterRoleBinding
	元数据型资源
		HPA,PodTemplate,LimitRange

创建资源的方法：
	apiserver仅接受JSON格式的资源定义；
	yaml格式提供配置清单，apiserver可自动将其转为json格式，而后再提交；

大部分资源的配置清单（5个大的字段）：
	apiserver: group/version 
		$ kubectl api-versions（命令）
	kind： 资源类别
	metadata:元数据 
		name
		namespace
		labels 	#标签
		annotations
		每个资源的引用PATH	/api/GROUP/VERSION/namespace/NAMESPACE/TYPE/NAME  #大写就是可以替换的具体的

	spec： 			# 期望的状态	，用来定义目标用户期望的状态 ，重要的字段
	status：			# 当前状态 ， 本字段由kubernetes集群维护，用户不能定义的，不能随意删除修改的；

kubectl explain pods				#看pod的资源配置清单怎么写，帮助信息
kubectl explain pods.metadata		#看pod下面的metadata字段怎么写  看这个FIELDS下面的示例
									# -required 必选字段
vim pod-demo.yaml 			#自己编写yaml
apiVersion: v1		#一级字段   kubectl explain pods 来获取
kind: Pod 	
metadata:
  name: pod-demo
  namespace: default
  labels: 
    app: myapp
    tier: frontend
spec:
  containers:
  - name: myapp 						# 列表需要在前面加 - 横线，映射数据用{}，所有的列表数据用[]
    image: ikubernetes/myapp:v1
    port:
    - name: http 						# 这个是port的列表
      containerPort: 80
    - name: https
      containerPort: 443				# 只是信息性的显示，并不真正的起到暴露端口的作用
  - name: busybox
    image: busybox:latest
    imagesPullPolicy: IfNotPresent		# 定义pull镜像的规则，默认有三个，Allways,Nerver，IfNotPresent
    command: 							
    - "/bin/sh"
    - "-c"	
    - "sleep 3600"
nodeSelector:							# 节点标签选择器，指定node节点在disktype: ssd上运行
	disktype: ssd

kubectl exec -it pod-demo -c myapp -- /bin/sh   # pod-demo是pod资源  -c指定容器  -- 指定命令  交互进入pod-demo的myapp容器里面

kubectl create -f pod-demo.yaml   #指定创建pod-demo.yaml的pod
kubectl delete -f pod-demo.yaml   #指定删除pod-demo.yaml的pod

#################################################################################################################

资源配置清单：
	自主式Pod资源
	资源的清单格式：
		一级字段：apiVersion(group/version),kind,metadata(name,namespace,labels,annotations,...),spec,status(只读)
	Pod资源：
		spec.containers<[]object>

		- name <string>					#容器名字
		  image <string>				#容器镜像
		  imagesPullPolicy <string>		#镜像获取策略
		    // Always(总是到仓库下载)，Never(从不下载)，IfNotPresent(如果本地不存在就下载)三个策略，默认是Always
		修改镜像中的默认应用：
			command（要运行的程序）  ， args（传递给程序的参数，比docker容器里的优先）

apiVersion: v1
kind: Pod
metadata:
	  name: pod-demo
	  namespace: default
	  labels:
	    app: myapp
	    tier: frontend
	  annotations：					# 可以直接edit修改的
	    node.example.com/create-by: "cluster admin"		# 资源注解
  spec:
    containers:
    - name: myapp
      image: ikubernetes/myapp:v1
      ports:
      - name: http 
        containerPort: 80				#这里的端口是说明一下，并不能实际真的暴露端口
      - name: https
        containerPort: 443
    - name: busybox
      image: busybox:latest
      imagesPullPolicy: IfNotPresent
      command:
      - "/bin/sh"
      - "-c"
      - "sleep 3600"
    nodeSelector: 					# 节点标签选择器，是这个pod的属性，不是容器的属性
      disktype: ssd 				# 创建的这个pod只在标签为disktype=ssd的节点上运行
	


##################################################################################################################

标签：
	key=value 
		key: 字母、数字、下划线 _ 、 横线- 、 点.  只能以字母开头，不能为空
		value： 可以为空，只能以字母数字开头及结尾，中间可使用 字母、数字、下划线 _ 、 横线- 、 点.

kubectl get pods --show-labels  # 查看标签
kubectl get pods -L app # -L用于指定显示指定资源对象类别下的所有资源的对应的标签的值，显示多个标签，可以多写,隔开
kubectl get pods -l app # -l 小写l 是过滤标签的作用，类似于grep，可以多写，逗号 , 隔开

	标签选择器：
		等值关系： =   ==   !=  
		集合关系： “key in ( , , ,)”     # 只要是括号里的任意一个就可以
				  key notin ( , , ,)
				  !key 

许多资源支持内嵌字段定义其使用的标签选择器：
	matchLabels: 直接给定键值
	matchExpressions: 基于给定的表达式来定义使用的标签选择器，{key:"KEY",operator:"OPERATOR",values:[VAL1,VAL2,...]}
		操作符: In , NotIn:  values字段的值必须为非空列表;
			   Exists , NOtExists： values字段的值必须为空列表;
kubectl label pods pod-demo replicas=canary		# 给名字叫pod-demo 的pod 打一个标签叫replicas=canary
kubectl label pods pod-demo replicas=stable --overwrite # 修改replicas的标签，要加一个--overwrite
kubectl labels nodes node01.example.com disktype=ssd 	# 给node01.example.com 的node节点打一个标签为 磁盘类型=固态 的标签

nodeSelector <map[string]string> 	节点标签选择器 # 映射值

nodeName <string>	 	# 直接指定pod运行在哪个node上面

annotations:    # 与label不同的地方在于，它不能用于挑选资源对象，仅用于为对象提供“元数据”，有些时候有些程序需要用到这些元数据

kubectl create -f pod-demo.yaml 		#用自己写的yaml创建一个pod

kubectl exec -it pod-demo -c myapp -- /bin/sh 	#进入pod-demo这个pod里面的，容器名叫myapp的容器里 -c 容器名


##########################################################################################################
Pod生命周期中的重要行为：
	初始化容器
	容器探测
		liveness	#检测容器是否存活
		readiness	#检测容器是否能正常提供服务

探针类型有三种： （探测生命周期的，每次定义的时候只定义其中一个就行）
	ExecAction ， TCPSocketAction , HTTPGetAction


每个Pod都必须要定义 livenessProbe（存活状态）和 readinessProbe（就绪状态）的探测
									pod存活状态探测的定义		# exec探针

apiVersion: v1
kind: Pod
metadata:
  name: liveness-exec-pod
  namespace: default
spec:
  containers:
  - name: liveness-exec-container
    image: busybox:latest
    imagesPullPolicy: IfNotPresent  	# 定义容器镜像的pull策略
    command: ["/bin/sh","-c","touch /tmp/healthy; sleep 30; rm -rf /tmp/healthy; sleep 3600"]
    livenessProbe: 	# 容器存活状态的定义探测
      exec: 		# 定义探测类型为exec
        command: ["test","-e","/tmp/healthy"] 		# 定义exec 探测命令
      initialDelatSeconds: 1	# 等容器起来1秒后再执行command 的命令
      periodSeconds: 3			# 每隔3秒探测一次
restartPolicy: Nerver 			# 定义pod 的重启策略


									pod就绪状态探测的定义		# httpGet探针

apiVersion: v1
kind: Pod
metadata:
  name: readiness-httpget-pod
  namespace: default
spec:
  containers:
  - name: readiness-httpget-container
    image: ikubernetes/myapp:v1
    imagesPullPolicy: IfNotPresent  	# 定义容器镜像的pull策略
    ports:
    - name: http
      containerPort: 80
    readinessProbe:
      httpGet:
        port: http
        path: /index.html
      initialDelatSeconds: 1	# 等容器起来1秒后再执行command 的命令
      periodSeconds: 3			# 每隔3秒探测一次
restartPolicy: Nerver 			# 定义pod 的重启策略


									pod启动后立即执行的沟子
apiVersion: v1
kind: Pod
metadata:
  name: poststart-pod
  namespace: default
spec:
  containers:
  image: busybox:latest
  imagesPullPolicy: IfNotPresent
  lifecycle:
    postStart:
      exec:
        command:["/bin/httpd","-f","-h /data/web/html"]
  command: ["/bin/sh"]			# 定义容器的command
  args: ["-c","mkdir -p /data/web/html ; echo 'Home Page' >> /data/web/html/index.html"]  # 给上面的command传递命令的参数  结合起来就是 /bin/httpd -f -h /data/web/html


##########################################################################################################
Pod的生命周期：
	状态： Pending	#挂起状态，已经创建但是调度尚未完成，没启动，没有找到符合条件的node节点
			
restartPolicy	#Pod重启策略，默认是Always 
	Always 		#总是重启
	OnFailure	#只有状态为错误而终止时才重启
	Never 		#从不重启
##########################################################################################################
回顾Pod
	apiVersion,kind,metadata,spec,status(只读字段，不用写也可以)

	spec:
		containers:
			name
			image
			imagesPullPolicy: Always，Never,IfNotPresent
			ports: 
				name
				containerPort 
			livenessProbe ------|
								|>>> ExecAction: exec， TCPSocketAction: tcpSocket , HTTPGetAction: httpGet
			readinessProbe -----|
			lifecycle
		nodeSelector
		nodeName
		restartPolicy：
			Always，Never,OnFailure

##########################################################################################################
