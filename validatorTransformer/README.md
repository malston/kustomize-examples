# 通过 transformer 验证资源

[kubeconform]: https://github.com/yannh/kubeconform
[插件]: ../../docs/plugins

kustomize 不会验证其输入或输出是否符合资源要求。

而另一个工具 [kubeconform] 提供了验证 k8s 资源的功能，例如：

```shell
$ kubeconform my-invalid-rc.yaml
my-invalid-rc.yaml - ConfigMap cm is invalid: problem validating schema. Check JSON formatting: jsonschema: '/data' does not validate with https://raw.githubusercontent.com/yannh/kubernetes-json-schema/master/master-standalone/configmap-v1.json#/properties/data/type: expected object or null, but got array
```

可以创建一个 Kustomize transformer [插件] 通过运行 [kubeconform] 来进行验证资源。

创建一个工作空间：

<!-- @makeWorkplace @test -->
```bash
DEMO_HOME=$PWD
mkdir -p $DEMO_HOME/valid
mkdir -p $DEMO_HOME/invalid
PLUGINDIR=$DEMO_HOME/kustomize/plugin/someteam.example.com/v1/validator
mkdir -p $PLUGINDIR
```

## 创建 transformer 插件

根据操作系统下载 [kubeconform] 的二进制文件并将其添加到 $PATH。

<!-- @downloadkubeconform @test -->
```bash
brew install kubeconform
```

transformer 插件将执行逻辑如下：

- 从 stdin 中读取资源并传递到 transformer 插件。
- transformer 插件的配置文件作为第一个参数传入。
- transformer 插件的工作目录是 kustomization 所在目录。
- 转换后的资源由插件写入 stdout 。
- transformer 返回值为0，则转化成功；如果 transformer 插件的返回值不为0，则 kustomize 认为转化期间存在错误。

我们可以写一个 bash 脚本作为用于验证资源的 transformer 插件，该脚本执行 [kubeconform] 二进制文件并返回正确的输出和退出码。
<!-- @writePlugin @test -->
```bash
cat <<'EOF' > $PLUGINDIR/Validator
#!/bin/bash

if ! [ -x "$(command -v kubeconform)" ]; then
  echo "Error: kubeconform is not installed."
  exit 1
fi

temp_file=$(mktemp).yaml
output_file=$(mktemp).yaml
cat - > $temp_file

kubeconform $temp_file > $output_file

if [ $? -eq 0 ]; then
    cat $temp_file
    rm $temp_file $output_file
    exit 0
fi

cat $output_file
rm $temp_file $output_file
exit 1

EOF
chmod +x $PLUGINDIR/Validator
```

## 使用 transformer 插件

创建一个包含有效 ConfigMap 和 transformer 插件的 Kustomization。

<!-- @writeKustomization @test -->
```bash
cat <<'EOF' >$DEMO_HOME/valid/configmap.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: cm
data:
  foo: bar
EOF

cat <<'EOF' >$DEMO_HOME/valid/validation.yaml
apiVersion: someteam.example.com/v1
kind: Validator
metadata:
  name: notImportantHere
EOF

cat <<'EOF' >$DEMO_HOME/valid/kustomization.yaml
resources:
- configmap.yaml

transformers:
- validation.yaml
EOF
```

创建一个包含无效 ConfigMap 和 transformer 插件的 Kustomization。

<!-- @writeKustomization @test -->
```bash
cat <<'EOF' >$DEMO_HOME/invalid/configmap.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: cm
data:
- foo: bar
EOF
# ConfigMap 的 data 字段需要传入的数据类型为 object，这里传入一个 array

cat <<'EOF' >$DEMO_HOME/invalid/validation.yaml
apiVersion: someteam.example.com/v1
kind: Validator
metadata:
  name: notImportantHere
EOF

cat <<'EOF' >$DEMO_HOME/invalid/kustomization.yaml
resources:
- configmap.yaml

transformers:
- validation.yaml
EOF
```

目录结构如下：

```bash
/tmp/tmp.fAYMfLZJs4
├── invalid
│   ├── configmap.yaml
│   ├── kustomization.yaml
│   └── validation.yaml
├── kustomize
│   └── plugin
│       └── someteam.example.com
│           └── v1
│               ├── kubeconform
│               └── Validator
└── valid
    ├── configmap.yaml
    ├── kustomization.yaml
    └── validation.yaml
```

定义一个 helper 函数在正确的的环境和插件标记运行 kustomize 。

<!-- @defineKustomizeBd @test -->
```bash
function kustomizeBd {
  XDG_CONFIG_HOME=$DEMO_HOME \
  kustomize build \
    --enable-alpha-plugins \
    $DEMO_HOME/$1
}
```

构建有效的 variant

<!-- @buildValid @test -->
```bash
kustomizeBd valid
```
输出的 ConfigMap 内容为：

```yaml
apiVersion: v1
data:
  foo: bar
kind: ConfigMap
metadata:
  name: cm
```

构建无效的 variant

```bash
kustomizeBd invalid
```

可以查看到输出错误日志为：

```shell
data: Invalid type. Expected: object, given: array
```

## 清理

<!-- @cleanup @test -->
```shell
rm -rf $DEMO_HOME
```
