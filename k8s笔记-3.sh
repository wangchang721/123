:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::			
																										存储卷
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::												
一： emptyDIR  空目录，如果存储卷在pod上，不在node上，那pod删了数据也没了，这个就是做临时目录的或者做缓存使用
	可以把内存分出一块做存储用，数据直接运行和存储在内存上，没有持久性
		 gitRepo  利用git仓库做特殊持久化的存储，宿主机有git，能从git仓库中下载和上传，

二： hostPath   把pod的存储关联到node主机上，这样pod删了，数据还在node主机上，只要node不挂，就可做持久化
								
三： 1： 传统的网络存储
					SAN： iscsi
					NAS： nfs  samba
		2： 分布式存储
					glusterfs ceph(rbd)  cephfs	
		3： 云存储 （k8s托管在这些云服务上，就用这些的）
					EBS(亚马逊) Azure Disk（微软的） 阿里云 	等


kubectl explain pods.spec.volumes    查看存储卷支持的哪些存储


示例一： emptyDIR
***********************************************************************************************
apiVersion: v1																																								*
kind: Pod  																																										*
metadata: 																																										*
	name: pod-demo 																																							*
	namespace: default																																					*
	labels:																																											*
		app: myapp																																								*
		tier: frontend																																						*
	annotations:																																								*
		node1.example.com/created-by: "cluster admin"																							*
spec: 																																												*
	containers: 																																								*
	- name: myapp 																																							*
		image: ikubernetes/myapp:v1																																*
		imagePullPolicy: IfNotPresent 																														*
		command: ['/bin/httpd','-f','-h /data/web/html'] 																					*
		ports: 																																										*
		- name: http  																																						*
			containerPort: 80 																																			*
		volumeMounts:						存储卷挂载																													*
		- name: html 																																							*
			mountPath: /usr/shar/nginx/html  指定挂载的路径,两个容器可以是不一样的路径	,先挂载再启动容器	*
		- name: https 																																						*
			containerPort: 443																																			*
	- name: busybox																																							*
		image: busybox:latest																																			*
		imagePullPolicy: IfNotPresent	 																														*
	  volumeMounts:						存储卷挂载																													*
		- name: html 																																							*
			mountPath: /data/  		指定挂载的路径 	 这个和上面的路径是共享的，虽然在一个pod的两个容器内			*	
		command: ["/bin/sh"]																																			*																																										
		args: ["-c","while true; do echo $(date) >> /data/index.html; sleep 2; done"]							*
	volumes:																																										*
	- name: html																																								*
		emptyDir:																																									*
			medium: {}  这个就是没有值定义存储媒介的，默认是空，就是disk，也能写Memory(内存)，就是当缓存用	*
			sizeLimit:    如果是内存的话，这里指定最大使用的内存数 																			*
一个pod内有两个容器，第一个容器运行http服务，第二个容器修改index.html文件，因为两个容器挂载卷是共享的	*		
***********************************************************************************************
			

示例二： hostPath
***********************************************************************************************
apiVersion: v1																																								*
kind: Pod  																																										*
metadata: 																																										*
	name: pod-vol-hostpath 																																			*
	namespace: default																																					*
spec: 																																												*
	containers: 																																								*
	- name: myapp 																																							*
		image: ikubernetes/myapp:v1																																*
		imagePullPolicy: IfNotPresent 																														*
		volumeMounts: 																																						*
		- name: html 																																							*
			mountPath: /usr/share/nginx/html/ 																											*
	volumes: 																																										*
	- name: html 																																								*
		hostPath: 																																								*
			path: /data/pod/volume1 																																*
			type: DirectoryOrCreate																																	*
然后在宿主机上 mkdir -p /data/pod/volume1 																											*
echo "node1.example.com" > /data/pod/volume1/index.html，但是节点宕机后，这个存储又会挂了 				*	
***********************************************************************************************



示例三： nfs
***********************************************************************************************
先搭建NFS服务，装包(nfs-utils)																																	*
配置 echo "/data/volumes  172.20.0.0/16    (rw,no_root_squash)" >  /etc/exports 								*
起服 systemctl start nfs    端口号： 2049																												*
客户端挂载命令： mount -t nfs node1:/data/volumes   /mnt 																				*
apiVersion: v1																																								*
kind: Pod  																																										*
metadata: 																																										*
	name: pod-vol-nfs 																																					*
	namespace: default																																					*
spec: 																																												*
	containers: 																																								*
	- name: myapp 																																							*
		image: ikubernetes/myapp:v1																																*
		imagePullPolicy: IfNotPresent 																														*
		volumeMounts: 																																						*
		- name: html 																																							*
			mountPath: /usr/share/nginx/html/ 																											*
	volumes: 																																										*
	- name: html 																																								*
		nfs: 																																											*
			path: /data/volume1 																																		*
			readOnly:  							默认是关闭的，默认就是读写都可以的，所以这里不用写										*
			server: node1     			nfs的服务端名字																										*
***********************************************************************************************




:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
																	pod--->volume--->pvc--->pv--->nfs/iscsi/ceph
													pod用户定义pod和pvc--->k8s集群管理员创建pv--->存储管理员创建nfs/iscsi/ceph
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
先把nfs/iscsi/ceph/ 这些映射做成单独的pv，再另外做好pvc，等pod需要volume时通过创建pvc来调取pv就可以了
pvc具体调用哪一个pv，是取决于pod定义使用多大的空间，也可以指定一人读一人写，或者多人读多人写
没有pvc的时候，pv不被调用，平时pv和pvc是分隔的。  一个pvc只能绑定对应的一个pv，但一个pvc能被多个pod调用。
定义pv的时候一定不能定义namespace，因为pv是属于整个集群的，要能被所有的集群调用，而pvc是属于某个名称空间的。

kubectl explain pvc.spec				 							
		accessModes					访问模式，就是指定一人读一人写，或者多人读多人写，是否支持多人访问
		resources						资源限制，至少指定多少
		selector						标签选择器，可以指定标签
		storageClassName		类的名称
		volumeMode					存储卷的模式
		volumeName					存储卷的名称，精确指定绑定某一个叫什么的pv

***********************************************************************************************
kubectl explain pv.spec.accessModes			pv的访问模式有三种
		ReadWriteOnce	 RWO			单路读写
		ReadOnlyMany	 ROX			多路只读
		ReadWriteMany	 RWX			多路读写
kubectl explain pv.spec.capacity 				指定	存储空间大小	
		storage: 10Gi 		 指定大小

回收策略： 默认是保存的，也可以定义成删除
***********************************************************************************************
准备工作：
				mkdir /data/volumes/v{1,2,3,4,5}
				vim /etc/exports
					/data/volumes/v1  172.20.0.0/16    (rw,no_root_squash)
					/data/volumes/v2  172.20.0.0/16    (rw,no_root_squash)
					/data/volumes/v3  172.20.0.0/16    (rw,no_root_squash)
					/data/volumes/v4  172.20.0.0/16    (rw,no_root_squash)
					/data/volumes/v5  172.20.0.0/16    (rw,no_root_squash)
				exportfs -arv 			不用重启nfs服务,配置文件就会生效在客户端
				showmount -e 				显示NFS服务器的输出清单

示例四： 定义pv  静态先部署好pv，只有pv满足pvc的需求才能绑定，pvc才能用，否则pvc找不到合适的pv就无法生效
***********************************************************************************************
apiVersion: v1																																								*
kind: PersistentVolume  																																			*
metadata: 																																										*
	name: pv001 				定义pv的时候一定不能定义namespace																					*	
	labels:																																											*
		name: pv001				但是可以定义一个标签，以后想选择还可以选择																	*
spec: 																																												*
		nfs: 																																											*
			path: /data/volumes/v1 																																	*
			readOnly:  							默认是关闭的，默认就是读写都可以的，所以这里不用写										*
			server: node1     			nfs的服务端名字																										*
		accessModes: ["ReadWriteMany","ReadWriteOnce"]																						*
		capacity: 																																								*
			storage: 2Gi																																						*
---																																														*
apiVersion: v1																																								*
kind: PersistentVolume  																																			*
metadata: 																																										*
	name: pv002 				定义pv的时候一定不能定义namespace																					*	
	labels:																																											*
		name: pv002				但是可以定义一个标签，以后想选择还可以选择																	*
spec: 																																												*
		nfs: 																																											*
			path: /data/volumes/v2 																																	*
			readOnly:  							默认是关闭的，默认就是读写都可以的，所以这里不用写										*
			server: node1     			nfs的服务端名字																										*	
		accessModes: ["ReadWriteOnce"]																														*
		capacity: 																																								*
			storage: 5Gi																																						*
---																																														*
apiVersion: v1																																								*
kind: PersistentVolume  																																			*
metadata: 																																										*
	name: pv003 				定义pv的时候一定不能定义namespace																					*	
	labels:																																											*
		name: pv003				但是可以定义一个标签，以后想选择还可以选择																	*
spec: 																																												*
		nfs: 																																											*
			path: /data/volumes/v3 																																	*
			readOnly:  							默认是关闭的，默认就是读写都可以的，所以这里不用写										*
			server: node1     			nfs的服务端名字																										*
		accessModes: ["ReadWriteMany","ReadWriteOnce"]																						*
		capacity: 																																								*
			storage: 20Gi																																						*
---																																														*
apiVersion: v1																																								*
kind: PersistentVolume  																																			*
metadata: 																																										*
	name: pv004 				定义pv的时候一定不能定义namespace																					*	
	labels:																																											*
		name: pv004				但是可以定义一个标签，以后想选择还可以选择																	*
spec: 																																												*
		nfs: 																																											*
			path: /data/volumes/v4 																																	*
			readOnly:  							默认是关闭的，默认就是读写都可以的，所以这里不用写										*
			server: node1     			nfs的服务端名字																										*	
		accessModes: ["ReadWriteMany","ReadWriteOnce"]																						*
		capacity: 																																								*
			storage: 10Gi																																						*
---																																														*
apiVersion: v1																																								*
kind: PersistentVolume  																																			*
metadata: 																																										*
	name: pv005 				定义pv的时候一定不能定义namespace																					*	
	labels:																																											*
		name: pv005				但是可以定义一个标签，以后想选择还可以选择																	*
spec: 																																												*
		nfs: 																																											*
			path: /data/volumes/v5 																																	*
			readOnly:  							默认是关闭的，默认就是读写都可以的，所以这里不用写										*
			server: node1     			nfs的服务端名字																										*	
		accessModes: ["ReadWriteMany","ReadWriteOnce"]																						*
		capacity: 																																								*
			storage: 10Gi																																						*										
***********************************************************************************************


示例五：  pvc
***********************************************************************************************
apiVersion: v1																																								*
kind: PersistentVolumeClaim 																																	*
metadata: 																																										*
	name: mypvc 																																								*	
	namespace: default 																																					*
spec: 																																												*
		accessModes: ["ReadWriteMany","ReadWriteOnce"]																						*
		resources: 																																								*
			requests:																																								*
				storage: 6Gi																																					*
---																																														*
apiVersion: v1																																								*
kind: Pod  																																										*
metadata: 																																										*
	name: pod-vol-pvc 																																					*
	namespace: default																																					*
spec: 																																												*
	containers: 																																								*
	- name: myapp 																																							*
		image: ikubernetes/myapp:v1																																*
		imagePullPolicy: IfNotPresent 																														*
		volumeMounts: 																																						*
		- name: html 																																							*
			mountPath: /usr/share/nginx/html/ 																											*
	volumes: 																																										*
	- name: html 																																								*
		persistentVolumeClaim:  																																	*
			claimName: mypvc						指定和哪个pvc确立绑定关系																			*
***********************************************************************************************


:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
																				StorageClass  存储类
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
满足用户不同的服务质量级别、备份策略和任意策略要求的存储需求。动态存储卷供应使用StorageClass进行实现，
其允许存储卷按需被创建。如果没有动态存储供应，Kubernetes集群的管理员将不得不通过手工的方式类创建新的存储卷。
通过动态存储卷，Kubernetes将能够按照用户的需要，自动创建其需要的存储

比如： 可以按nfs为一类，ceph为一类，本地存储为一类，云存储为一类等，根据综合服务质量或者仅仅按I/O性能来分类

1）集群管理员预先创建存储类（StorageClass）；

2）用户创建使用存储类的持久化存储声明(PVC：PersistentVolumeClaim)；

3）存储持久化声明通知系统，它需要一个持久化存储(PV:PersistentVolume)；

4）系统读取存储类的信息；

5）系统基于存储类的信息，在后台自动创建PVC需要的PV；

6）用户创建一个使用PVC的Pod；

7）Pod中的应用通过PVC进行数据的持久化；

8）而PVC使用PV进行数据的最终持久化处理。



:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
																				configMap（cm）			配置中心
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
在每一个configmap中，所有的配置信息都保存为键值格式
用于存储被Pod或者其他资源对象（如RC）访问的信息。这与secret的设计理念有异曲同工之妙，
主要区别在于ConfigMap通常不用于存储敏感信息，而只存储简单的文本信息。

创建pod时，对configmap进行绑定，pod内的应用可以直接引用ConfigMap的配置。
相当于configmap为应用/运行环境封装配置。pod使用ConfigMap，通常用于：设置环境变量的值、设置命令行参数、创建配置文件

ConfigMap用于保存配置数据的键值对，可以用来保存单个属性，也可以用来保存配置文件。

ConfigMap同Kubernetes的另一个概念secret类似，区别是ConfigMap主要用于保存不包含敏感信息的明文字符串。

配置容器化应用的方式
	1: 自定义命令行参数
				args：  			传递参数的方法
	2: 把配置文件直接熔进镜像

	3: 环境变量
			(1) Cloud Native的应用程序一般可直接通过环境变量加载配置
			(2) 通过entrypolint脚本来预处理变量为配置文件中的配置信息

	4: 存储卷

创建方式：

示例：kubectl create configmap special-config --from-literal=i042416=jerry

		 上述命令行创建了一个名为special-config的键值对，key为i042416, 值为jerry


一：通过直接在命令行中指定configmap参数创建，即--from-literal
二：通过指定文件创建，即将一个配置文件创建为一个ConfigMap--from-file=<文件>
三：通过指定目录创建，即将一个目录下的所有配置文件创建为一个ConfigMap，--from-file=<目录>

示例一： --from-literal
*****************************************************************************************************************
kubectl create configmap nginx-config --from-literal=nginx_port=80 --from-literal=server_name=myapp.example.com *
*****************************************************************************************************************

示例二： --from-file=<文件>  在pod创建时指定导入提前写好的配置文件，只在启动时有效，启动后就无法动态修改配置了
*******************************************************************************************
vim www.conf 																																							*
	server { 																																								*
		server_name  myapp.example.com; 																											*
		listen 80; 																																						*
		root /data/web/html/; 																																*
	} 																																											*
																																													*
kubectl create configmap nginx-www --from-file=/root/www.conf  														*
kubectl get cm nginx-www -o yaml    查看nginx-www 的yaml格式 															*
kubectl describe cm nginx-www 			查看详细信息 																						*
键名是 文件名 www.cconf ， 键值是 文件内容 																									*
------------------------------------------------------------------------------------------*
apiVersion: v1																																						*
kind: Pod  																																								*
metadata: 																																								*
	name: pod-cm-1 																																					*
	namespace: default																																			*
	labels:																																									*
		app: myapp																																						*
		tier: frontend																																				*
	annotations:																																						*
		node1.example.com/created-by: "cluster admin"																					*
spec: 																																										*
	containers: 																																						*
	- name: myapp 																																					*
		image: ikubernetes/myapp:v1																														*
		ports: 																																								*
		- name: http 																																					*
			containerPort: 80 																																	*
    env: 													      定义环境变量																				*
    - name: NGINX_SERVER_PORT 					应该是容器能读取和处理的变量，没有会生成新的 					*
    	valueFrom:  											引用的值 																					*
    		configMapKeyRef: 								configmap所引用的值得内容														*
    			name: nginx-config  					只在启动时有效，启动后就改变不了了										*
    			keys: nginx_port 																																*
    - name: NGINX_SERVER_NAME 																														*
    	valueFrom: 																																					*
    		configMapKeyRef: 																																	*
    			name: nginx-config 																															*
    			keys: server_name  			 																												*
*******************************************************************************************


示例三：  用存储卷的方式挂载配置文件，可以在pod运行后动态修改环境变量
*******************************************************************************************
apiVersion: v1																																						*
kind: Pod  																																								*
metadata: 																																								*
	name: pod-cm-1 																																					*
	namespace: default																																			*
	labels:																																									*
		app: myapp																																						*
		tier: frontend																																				*
	annotations:																																						*
		node1.example.com/created-by: "cluster admin"																					*
spec: 																																										*
	containers: 																																						*
	- name: myapp 																																					*
		image: ikubernetes/myapp:v1																														*
		ports: 																																								*
		- name: http 																																					*
			containerPort: 80 																																	*
		volumeMounts:  																																				*
		- name: nginxconf  										指定下面volumes定义的挂在卷的名称									*
			mountPath: /etc/nginx/config.d/			指定容器内挂载的路径 															*
			readOnly: true 											只读为真的话，容器内无法修改												*
	volumes:  																																							*
	- name: nginxconf 											定义一个挂载卷的名称															* 
	  configMap:  																																					*
	  	name: nginx-config (示例一创建的configMap的名字) 																			*
*******************************************************************************************


:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
																			secret  (安全的configMap，不明文显示)
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
三种类型
	generic													通用的，一般保存密码，数据之类的，例如放连接mysql的账号密码等
	tls															私钥和证书的话，必须用tls
	docker-registry									保存docker-registry信息，也就是保存本地连接docker私有仓库的账号密码信息

kubectl create secret generic mysql-root-password --from-literal=password=密码    命令行设置password=密码
kubectl get secret mysql-root-password -o yaml 	  查看yaml格式的详细信息，密码会以base64格式显示
echo "base64加密的字符" | base64 -d      解密base64


示例一：	 					通过env的形式注入进去，变量值显示的是明文的
*******************************************************************************************
apiVersion: v1																																						*
kind: Pod  																																								*
metadata: 																																								*
	name: pod-secret-1 																																			*
	namespace: default																																			*
	labels:																																									*
		app: myapp																																						*
		tier: frontend																																				*
	annotations:																																						*
		node1.example.com/created-by: "cluster admin"																					*
spec: 																																										*
	containers: 																																						*
	- name: myapp 																																					*
		image: ikubernetes/myapp:v1																														*
		ports: 																																								*
		- name: http 																																					*
			containerPort: 80 																																	*
    env: 													      定义环境变量																				*
    - name: MYSQL_ROOT_PASSWORD 				应该是容器能读取和处理的变量，没有会生成新的 					*
    	valueFrom:  											引用的值 																					*
    		secretKeyRef: 									secret所引用的值得内容															*
    			name: mysql-root-password  		上面命令行创建的名字																*
    			keys: password  							上面命令行创建的键值名 															*																							
*******************************************************************************************
########################################################################################################
########################################################################################################





























































































































































































































































