

除了pod是保存在node节点上，其他的k8s服务基本都是保存在etcd上
配置中心：configmap 比如有20个tomcat要运行，统一从配置中心加载配置，20个pod在运行，要修改配置文件，就从配置中心去修改，不用一个个pod的改

kubtctl [command] [TYPE] [NAME] [flags]
  commadn: | create | delete | get | describe | apply
  type: 资源对象类型，严格区分大小写
  flags： 可选参数， -n 指定namespaces 

资源对象类型 
  daemonsets  ds                        
  deployments deploy
  ReplicaSet  rs
  events    ev 
  endpoints ep 
  horizontalpodautoscalers  hps 
  ingresses   ing                         外接入口
  jobs                                  
  nodes     no                          节点
  namespaces  ns 
  	kubectl create namespaces dev 		创建一个名字叫dev的名称空间
  	kubectl gte ns 						查看k8s上的名称空间
  	kubectl delete ns/dev 				删除叫dev的名称空间（不要乱删除名称空间，因为会把名称空间下面的资源都删掉）
  pods    po 
  persistentvolumes     pvc             
  resourcequotas    quota
  replicationcontrollers  rc 
  secerts                              
  service   svc 
  serviceaccounts   sa 



练习
  # 同时查看pod和service 等多种资源对象
  kubectl get pod/etcd-master.example.com svc/kubernetes-dashboard -n kube-system  

kubectl 子命令

  -l 过滤 -w 监控   kubectl get pods -l app=myapp -w    # 获取pods信息，-l类似grep，-w类似tail -f


  secret 			kubectl create secret tls 名字 --cert=/root/test.crt --key=/root/test.key  创建一个tls类型的指定证书和私钥的
  expose 			kubectl expose deployment redis --port=6379   	创建一个deployment里面名叫redis的暴露的端口为6379
  annotate  											添加或者更新资源对象的信息
  explain 			kubectl explain pod.spec 			查看相关的详细信息和帮助
  attach 		   	kubectl attach pod -c container    链接一个正在运行的pod
  cluster-info     	kubectl cluster-info     			显示集群信息
  completion   	   	kubectl completion bash    		输出shell命令执行后的返回码
  config  	   	   	kubtctl config get-clusters    		修改kubeconfig配置文件
  create		   	kubectl create -f kube-user.yaml   	从配置文件创建资源对象
  delete 		   	kubectl delete -f kube-user.yaml   	从配置文件删除资源对象
  apply 		   	kubectl apply -f filename  			从配置文件更新资源对象，修改一个yaml文件后，apply可以更新生效
  describe         	kubectl describe sa/pod       		查看资源对象的详细信息
  edit  		   	kubtctl edit sa/pod         		编辑资源对象的属性         
  label   		   	kubectl label node/pod 名字 a=b     	为资源对象或pod打一个a=b的标签,打标签
  logs				kubectl logs myapp-ds-dvwdf			查看myapp-ds-dvwdf这个的日志
  					kubectl logs -f <pod-name>			类似tail -f 的方式查看这个pod的日志
  patch  		   	kubectl patch deployment myapp-deploy -p '{sepc:{"replicas":5}}'  打补丁。 把replicas改成5，类似vim myapp-deplo.yaml，外面是单引号，里面就用双引号
  		           	kubectl patch deployment myapp-deplo -p '{"specc":{"strategy":{"rollingUpdate":{"maxSurge":1,"maxUnavailable":0}}}}'
  exec				kubectl exec pod名字 -- netstat -tnl  查看pod的暴露的端口信息
  set image        	kubectl set image deployment myapp-deploy myapp=ikubernetes/myapp:v3	#升级容器版本v1变成v2，指明容器的镜像版本号为v2
  
  rollout  		   	kubectl rollout undo         				    # 版本回滚
  rollout pause    	kubectl rollout pause deployment myapp-deploy   # 暂停myapp-deplay的滚动更新
  rollout resume   	kubectl rollout resume deployment myapp-deploy  # 启动刚才暂停的滚动更新
  rollout status   	kubectl rollout status deployment myapp-deploy  # 持续监控显示滚动更新的状态
  rollout history  	kubectl rollout history deployment myapp-deploy # 显示myapp-deplay的历史版本记录
  rollout undo     	kubectl rollout undo deployment myapp-deploy --to-revision=1  # 回滚到第一个版本


								
								Deployment  ----控制---->  ReplicaSet  ----控制---->  Pod


#########################################################################################################
Pod控制器：
  ReplicaSet: 三个组件组成，1：用户期望的Pod副本数量 2：标签选择器 3：实际中不够定义的Pod副本数量，则自动多退少补
  Deployment： 管理无状态，关注群体的，（鸡群）通过控制ReplicaSet来控制Pod，建立在ReplicaSet之上，支持滚动回滚，要掌握的pod控制器，目前最好的控制器
  DaemonSet： 在集群内的每个节点上(也可以是在有限的node上)只运行一个pod，用于系统级的服务，如日志（一个node节点上部署一个日志收集服务的agent就可以了，），守护进程，持续运行
  Job： 只完成一次就退出，没完成不退出
  Cronjob： 周期性运行，类似于crontab
  StatefulSet： 关注个体，管理有状态，比如redis，通过自己写的脚本恢复，管理有状态是很麻烦的

Helm： 类似于yum,直接使用helm就能安装应用，大量主流应用基本都有

#########################################################################################################

定义ReplicaSet（可以简写为rs）
  kubectl explain rs      # 查看rs的yaml帮助
	replicas: 定义副本数    selector: 标签选择器    template: Pod模板（对象）
*********************************************************************************************
apiVersion: apps/v1																			*
kind: ReplicaSet 																			*
metadata: 																					*
	name: myapp 																			*
	namespaces: default 																	*
spec:							# 控制器的spec												*
	replicas: 2																				*
	selector:					# 标签选择器 												*
		matechLabels:			# 标签选择器下属的字段（定义标签选择标准的： key,value） 		*
			app: myapp 																		*
			release: canary 																*
	template: 																				*
		metadata: 																			*
			name: myapp-pod		# 这个名字没啥用 												*
			labels: 			# 必须要定义 												*
				apps: myapp 																*
				release: canary # 符合上面标签选择器定义的标准									*
				enviroment: qa  # qa环境用到的（不写也可以，这里是举例的） 						*
		spec:					# pod的spec 													*
			containers: 																	*
			- name: myapp-container 														*
			  image: ikubernetes:myapp:v1 													*
			  ports:  																		*
			  - name: http 																	*
			    containerPort: 80 															*
*********************************************************************************************
####################################################################################################

deployment利用ReplicaSet的版本更新，
灰度，金丝雀，蓝绿
比如固定是5个，允许只能多一个，那就是加一个新的，删一个老的，直到最好5个全是新的（允许只能少一个同理）
允许可多可少，也是同理
如果允许多5个，那就直接加5个新的，再把5个老的全部删掉



deployment.strategy: 定义更新策略 
	Recreate				# 重建式更新，就是删一个建一个
	RollingUpdate			# 滚动升级，控制更新粒度，就是更新期间最多pod副本能多几个，或者能少几个
		maxSurge			# 最多能超出的副本数为几个 1:直接指定数量 2:百分比 %
		maxUnavailable		# 最多有几个不可用

*****************************************************************
apiVersion: apps/v1												*
kind: Deployment 												*
matedata: 														*
	name: myapp-deploy 											*
	namespaces: default 										*
spec: 															*
	replicas: 2 												*
	selector:  													*
		matechLabels: 											*
			app: myapp 											*
			release: canary 									*
	template: 													*
		metadata: 												*
			labels: 											*
				app: myapp 										*
				release: canary 								*
		spec: 													*
			containers: 										*
			- name: myapp 										*
			  image: ikubernetes/myapp:v1 						*
			  ports: 											*
			  - name: http 										*
			    containerPort: 80 								*
*****************************************************************
####################################################################################################

daemonsets 确保集群中每个（部分）node运行一份pod副本，当node加入集群时创建pod，
当node离开集群时回收pod。如果删除DaemonSet，其创建的所有pod也被删除，DaemonSet中的pod覆盖整个集群。

当需要在集群内每个node运行同一个pod，使用DaemonSet是有价值的，以下是典型使用场景：

运行集群存储守护进程，如glusterd、ceph。
运行集群日志收集守护进程，如fluentd、logstash。
运行节点监控守护进程，如Prometheus Node Exporter, collectd, Datadog agent, New Relic agent, or Ganglia gmond

daemonsets.revisionHistoryLimit   保存历史版本数，指定保存几个历史版本数量

*****************************************************************
apiVersion: apps/v1												*
kind: Deployment 												*
metadata: 														* 				
	name: redis 												*
	namespaces: default 										*
spec: 															*
	replicas: 1 												*
	selector: 													*
		matechLabels: 											*
			app: redis 											*
			role: logstor 										*
		template: 												*
			metadata: 											*
				labels: 										*
					app: redis 									*
					role: logstor 								*
			spec: 												*
				containers: 									*
				- name: redis 									*
				  image: redis:4.0-alpine 						*
				  ports: 										*
				  - name: redis 								*
				    containerPort: 6379 	 					*
				    											*
--- 					---是分隔号，一个yaml里可以定义多个资源 	*
 																*
apiVersion: apps/v1												*
kind: DaemonSet  												*
matedata: 														*
	name: filebeat-ds  											*
	namespaces: default 										*
spec: 															*
	selector:  													*
		matechLabels: 											*
			app: filebeat 										*
			release: stable 									*
	template: 													*
		metadata: 												*
			labels: 											*
				app: filebeat  									*
				release: stable 								*
		spec: 													*
			containers: 										*
			- name: filebeat 									*
			  image: ikubernetes/filebeat:5.6.5-alpine			*
			  env:   定义环境变量 								*
			  - name: REDIS_HOST 								*
			    value: redis.default.svc.cluster.local			*
			    	   服务名.名称空间.本地的域名后缀 				*
			  - name: REDIS_LOG_LEVEL 							*
			  	value: info  									*
*****************************************************************

########################################################################################################				

service 
	ClusterIP，NodeIP
		client-->NodeIP:NodePort-->ClusterIP:ServicePort-->PodIP:containerPort
		客户端-->节点IP:节点端口-->集群内部IP:映射端口-->PodIP:pod内容器的端口
	No ClusterIP：Headless Service
		ServiceName-->PodIP		


	k8s中有三类ip地址： node网络（配置在node节点上），pod网络（配置在pod上），cluster网络（集群网络，虚拟的）
	工作模式： userspace:1.1-    iptables:1.10-     ipvs:1.11+
	类型：
		ExternalName：	把集群外的服务引入到集群内部来使用
			- CNAME（外网的负载均衡名称，参考AWS的web-1459586871.us-east-1.elb.amazonaws.com）外网的DNS
			把外部名称映射成内部名称，内部有coredns kubectl get svc -n kube-system #查看k8s系统的svc，内部dns
		ClusterIP:	默认的是这个，集群内IP，仅用于集群内通信，私网地址，无法接入集群外部的通信
		NodePort：  集群内部接入集群外部的通信，
		LoadBalancer：	自动在外部触发的负载均衡器
	资源记录：
		SVC_NAME.NS_NAME.DOMAIN.LTD.	服务名.名称空间.自己的域名后缀
		svc.cluster.local.              集群默认的域名
		比如： redis.default.svc.cluster.local.
*****************************************************************************************************
apiVersion: v1																						*
kind: Service 																						*
metadata: 																							*
	name: redis 																					*
	namespaces: default 																			*
spec: 																								*
	selector: 																						*
		app: redis 			 																		*
		role: logstor		角色 																	*
	clusterIP: 10.97.97.97	默认就是clusterIP，IP地址也会自动分配，也可以自己指定IP地址,建议不要指定地址	*
	type: ClusterIP 																				*
	ports: 																							*
	- port: 6379			service的IP定义的端口 													*
	  targetPort: 6379		Pod上的端口 																*
	 		 																						*
*****************************************************************************************************

*****************************************************************************************************
apiVersion: v1																						*
kind: Service 																						*
metadata: 																							*
	name: myapp 																					*
	namespaces: default 																			*
spec: 																								*
	selector: 																						*
		app: myqpp 			 																		*
		release: canary		 																		*
	clusterIP: 10.99.99.99	默认就是clusterIP，IP地址也会自动分配，也可以自己指定IP地址,建议不要指定地址	*
	type: NodePort 																					*
	ports: 																							*
	- port: 80				service的IP定义的端口 													*
	  targetPort: 80		Pod上的端口 																*
	  nodePort: 30080 		集群对外发布的端口(默认是从30000到32767之间自动分配的)，不指定也可以的		*
	  # curl http://172.20.0.66:30080/hostname.html   在外部直接访问node节点地址的30080端口是可以的 	*
*****************************************************************************************************
kubectl patch svc myapp -p '{"spec:"{"sessionAffinity":"ClientIP"}}' 
# 打补丁，给名字为myapp的svc加一行，在spec下面加一行定义sessionAffinity:ClientIP（客户端IP），这样外面访问的
# 时候，后端调用的Pod就是只调用一个pod，而不是轮询的负载式的访问，默认是：None ，改为None后，又变成负载的了

*****************************************************************************************************
apiVersion: v1																						*
kind: Service 																						*
metadata: 																							*
	name: myapp-svc 																				*
	namespaces: default 																			*
spec: 																								*
	selector: 																						*
		app: myqpp 			 																		*
		release: canary		 																		*
	clusterIP: None		# 这里为None的话，就是headlessIP（无头IP），	type（类型）只能是clusterIP		*
	ports: 																							*
	- port: 80				service的IP定义的端口 													*
	  targetPort: 80		Pod上的端口 																*
clusterIP是None（无头）的话，域名解析出来就是集群内的pod的ip地址，如果指定clusterIP的话，那就只解析指定地址*
*****************************************************************************************************

dig -t A myapp-svc.default.svc.cluster.local @10.96.0.10  # dig域名解析 @地址，就是指定解析服务器的地址
kubectl get svc -n kube-system   # 查看k8s系统的svc
kube-dns  ClusterIP 10.96.0.10   # k8s集群内自己的dns域名解析服务

######################################################################################################
Ingress Controller和Ingress不一样
Ingress Controller: 入口控制器，即外部流量进入k8s集群必经之口,是自己独立运行的一个控制器，或者一组pod资源，它通常就是
一个应用程序，这个应用程序就是拥有七层代理能力和调度能力的应用程序
虽然k8s集群内部署的pod、server都有自己的IP，但是却无法提供外网访问，以前我们可以通过监听NodePort的方式暴露服务，
但是这种方式并不灵活，生产环境也不建议使用。Ingresss是k8s集群中的一个API资源对象，
扮演边缘路由器(edge router)的角色，也可以理解为集群防火墙、集群网关，我们可以自定义路由规则来转发、管理、暴露服务(一组pod)
非常灵活，生产环境建议使用这种方式。另外LoadBlancer也可以暴露服务，不过这种方式需要向云平台申请负债均衡器
虽然目前很多云平台都支持，但是这种方式深度耦合了云平台，所以你懂的

七层代理一般三种选择：Nginx Traefik Envoy

外部的负载均衡器--->node里的pod里的service--->Ingress Controller--->Ingress--->service(只做后端pod归组)

安装配置 Ingress-nginx 
在 https://github.com/kubernetes/ingress-nginx/tree/master/deploy 把相关的yaml文件都下载下来或者gitclone下来
namespaces.yaml  configmap.yaml  rbac.yaml  tcp-services-configmap.yaml  with-rbac.yaml default-backend.yaml udp-services-configmap.yaml

第一步： kubectl apply -f namespaces.yaml 或者 kubectl create namespaces ingress-nginx # 先创建名称空间（名字可自己定义） 
第二步： 剩下其他的没有先后顺序，可以批量创建 kubectl apply -f ./  # apply 会自动指引目录下的所有文件

kubectl explain ingress.spec
	backend 	定义后端，表示后端有哪几个主机
	rules		定义规则的
	tls			只有需要把ingress定义成https，才需要配置这个tls


*****************************************************************************************************
apiVersion: extensions/v1beta1																		*
kind: Ingress 																						*
metadata: 																							*
	name: ingress-myapp 																			*
	namespace: default  																			*
	annotations:        注解，非常重要																*
		kubernetes.io/ingress.class: "nginx"	 前缀/键名: nginx 必须指明为nginx 					*
spec: 																								*
	rules: 																							*
	- host: node1.example.com 	定义主机(靠这个域名识别虚拟主机)   									*
	  http: 					协议为http				 											*
		paths:					表示以路径来定义的	 												*
		- path: /testpath		前端	路径,默认是根 /													*
		  backend: 				后端 																*
		  	serviceName: myapp 			 															*
	        servicePort: 80				 															*
*****************************************************************************************************
上面定义的这个，会自动映射到容器内的nginx配置文件里

openssl genrsa -out test.key 2048		# 自己做个私钥
openssl req -new -x509 -key test.key -out test.crt -subj 回车，填写信息最后的CN=自己的域名

*****************************************************************************************************
apiVersion: v1																						*
kind: Service 																						*
metadata: 																							*
	name: tomcat 																					*
	namespaces: default 																			*
spec: 																								*
	selector: 																						*
		app: tomcat 			 																	*
		release: canary		 																		*
	ports: 																							*
	- name: http																					*
	  port: 8080				service的IP定义的端口 												*
	  targetPort: 8080		Pod上的端口 																*
	- name: http																					*
	  port: 8009				service的IP定义的端口 												*
	  targetPort: 8009		Pod上的端口 																*
--- 																								*
apiVersion: apps/v1																					*
kind: Deployment 																					*
matedata: 																							*
	name: tomcat-deploy 																			*
	namespaces: default 																			*
spec: 																								*
	replicas: 3 																					*
	selector:  																						*
		matechLabels: 																				*
			app: tomcat 																			*
			release: canary 																		*
	template: 																						*
		metadata: 																					*
			labels: 																				*
				app: tomcat 																		*
				release: canary 																	*
		spec: 																						*
			containers: 																			*
			- name: tomcat 																			*
			  image: tomcat: 8.5.32-jre8-alpine														*
			  ports: 																				*
			  - name: http 																			*
			    containerPort: 8080 																*
			  - name: ajp																			*
			    containerPort: 8009  																*
--- 			    																				*
apiVersion: extensions/v1beta1																		*
kind: Ingress 																						*
metadata: 																							*
	name: ingress-tomcat 																			*
	namespace: default  																			*
	annotations:        注解，非常重要																*
		kubernetes.io/ingress.class: "nginx"	 前缀/键名: nginx 必须指明为nginx 					*
spec: 																								*
	rules: 																							*
	- host: tomcat.example.com 	定义主机(靠这个域名识别虚拟主机)   									*
	  http: 					协议为http				 											*
		paths:					表示以路径来定义的	 												*
		- path: /testpath		前端	路径,默认是根 /													*
		  backend: 				后端 																*
		  	serviceName: tomcat 			 														*
	        servicePort: 8080				 														*
*****************************************************************************************************

########################################################################################################



















































