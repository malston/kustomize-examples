# Demo: multibases with a common base

`kustomize` encourages defining multiple variants -
e.g. dev, staging and prod,
as overlays on a common base.

It's possible to create an additional overlay to
compose these variants together - just declare the
overlays as the bases of a new kustomization.

This is also a means to apply a common label or
annotation across the variants, if for some reason
the base isn't under your control. It also allows
one to define a left-most namePrefix across the
variants - something that cannot be
done by modifying the common base.

The following demonstrates this using a base
that is just a single pod.

Define a place to work:

```sh
DEMO_HOME=$(mktemp -d)
```

Define a common base:

```sh
BASE=$DEMO_HOME/base
mkdir $BASE

cat <<EOF >$BASE/kustomization.yaml
resources:
- pod.yaml
EOF

cat <<EOF >$BASE/pod.yaml
apiVersion: v1
kind: Pod
metadata:
  name: myapp-pod
  labels:
    app: myapp
spec:
  containers:
  - name: nginx
    image: nginx:1.7.9
EOF
```

Define a dev variant overlaying base:

```sh
DEV=$DEMO_HOME/dev
mkdir $DEV

cat <<EOF >$DEV/kustomization.yaml
resources:
- ./../base
namePrefix: dev-
EOF
```

Define a staging variant overlaying base:

```sh
STAG=$DEMO_HOME/staging
mkdir $STAG

cat <<EOF >$STAG/kustomization.yaml
resources:
- ./../base
namePrefix: stag-
EOF
```

Define a production variant overlaying base:

```sh
PROD=$DEMO_HOME/production
mkdir $PROD

cat <<EOF >$PROD/kustomization.yaml
resources:
- ./../base
namePrefix: prod-
EOF
```

Then define a _Kustomization_ composing three variants together:

```sh
cat <<EOF >$DEMO_HOME/kustomization.yaml
resources:
- ./dev
- ./staging
- ./production

namePrefix: cluster-a-
EOF
```

Now the workspace has following directories

> ```sh
> .
> ├── base
> │   ├── kustomization.yaml
> │   └── pod.yaml
> ├── dev
> │   └── kustomization.yaml
> ├── kustomization.yaml
> ├── production
> │   └── kustomization.yaml
> └── staging
>     └── kustomization.yaml
> ```

Confirm that the `kustomize build` output contains three pod objects from dev, staging and production variants.

<!-- @confirmVariants @testAgainstLatestRelease -->
```
test 1 == \
  $(kustomize build $DEMO_HOME | grep cluster-a-dev-myapp-pod | wc -l); \
  echo $?
  
test 1 == \
  $(kustomize build $DEMO_HOME | grep cluster-a-stag-myapp-pod | wc -l); \
  echo $?
  
test 1 == \
  $(kustomize build $DEMO_HOME | grep cluster-a-prod-myapp-pod | wc -l); \
  echo $?    
```
Similarly to adding different `namePrefix` in different variants, one can also add different `namespace` and compose those variants in
one _kustomization_. For more details, take a look at [multi-namespaces](multi-namespace.md).
