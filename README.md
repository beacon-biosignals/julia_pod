### purpose

`julia_pod` will drop you into a julia REPL, which:
- is running in a k8s pod
- is set up for spinning up a K8sClusterManagers cluster
- has your julia project root and `~/.julia/logs` dirs
  synced with the running container, 
  so that if you make changes to your `src/` or `dev/`
  using a local editor
  or add dependencies to your project 
  from within your julia session, things will just work.
  Julia REPL history will also transfer between local
  julia and julia_pod sessions.

The point of this, beyond making it easier to use a k8s cluster,
is that your dev env now closely resembles a 
reproducible/auditable job running env, into which you can 
run jobs by doing:

`julia_pod '...'` with a single arg, which is set up the same way 
as `julia_pod`, except the single arg is passed to julia
as `-e '...'`; this is achieved by appending `-e '...'` to the
`containers.command` value in the pod spec defined in
`driver.yaml.template`.

By default the julia project root and `~/.julia/logs` dirs are 
synced, even when run with a julia command as arg. To not sync,
pass in `julia_pod --no-sync [...]`; this will just copy whatever
the `Dockerfile` has indicated into the docker image build,
by default `src/`, `dev/`, `Project.toml` and `Manifest.toml`,
but not sync your project folder with the container while 
it is running.


### installation

##### Prerequisites

- a working `kubectl` configured to connect with a k8s cluster
- make sure your docker version is `>= 20.10.7`, and set up `docker buildx`:
    - `export DOCKER_BUILDKIT=1` and `export DOCKER_CLI_EXPERIMENTAL=enabled` (for example in your .bashrc)
- make sure your docker is using the `docker` driver and not a `docker-container` driver
  by doing `docker buildx use default` (otherwise re-builds may be slower.)
- `devspace` CLI (installation is easy)
- set your `EDITOR` environment variable to your favorite editor
  (putting this in your shell startup script is generally good idea)
- if your system doesn't have it already, install `jq` (https://stedolan.github.io/jq/download/)

To install docker version `>= 20.10.7`, go to `https://download.docker.com/linux/`,
pick the flavor of linux closest to yours, then go to `x86_64/stable/Packages`
and download the latest version of all 4 packages
(`containerd.io`, `docker-ce`, `docker-de-cli`, `docker-ce-rootless-extras`)
and install them by hand, using e.g.
`sudo yum install /path/to/package.rpm`
or `sudo dpkg -i /path/to/package.deb`

To install `buildx` on Amazon linux images, follow
[docker/buildx#132 (comment)](https://github.com/docker/buildx/issues/132#issuecomment-695768757).

Generally, docker's buildx has seen several recent improvements,
upgrading to a recent version is recommended.

##### the actual install

Update `add_me_to_your_PATH/accounts.sh` with the following ENV
vars for your cluster:
- `KUBERNETES_NAMESPACE`
- `KUBERNETES_SERVICEACCOUNT`
- `IMAGE_REPO` -- a docker repo from which container images can be pulled

To give your `julia_pod` access to private packages set the following ENV vars:
- `PRIVATE_REGISTRY_URL` -- URL to the private Julia package registry
- `GITHUB_TOKEN_FILE` -- Path to a file containing [Personal Access Token](https://docs.github.com/en/github/authenticating-to-github/keeping-your-account-and-data-secure/creating-a-personal-access-token) with "repo" scope access.

Then just add `add_me_to_your_PATH/` to your path, or call
`/path/to/add_me_to_your_PATH/julia_pod`.


### usage

`julia_pod --image=julia:1.6`

will start a k8s job running `julia` in the stock `julia:1.6` image,
and drop you into that REPL.

`julia_pod`

run from a julia project root dir will build a docker image for your
project, push it to ECR, and run it in the cluster, dropping you
into a julia REPL.

`--image` lets you pass in a publicly available image name or ECR image 
tag. If absent, `julia_pod` will look for a `Dockerfile` in your current
folder to build an image from, and if that's not present it'll use
`add_me_to_your_PATH/Dockerfile.template`. Note that
custom `Dockerfile`s need to be structured
with the same build stages as `add_me_to_your_PATH/Dockerfile.template`.

`--port-forward` port forwards between localhost and the julia
pod, e.g. `--port-forward=1234:1234`.

`--julia` is the julia command to be run in the container, as a
comma-separated list of "-quoted words. Defaults to `"julia"`.

`--runid` will allow customizing the "run ID" used to choose the
name of the kubernetes job.

If no `--image=...` is passed in, `julia_pod` will call `accounts.sh`
and then `build_image` to build one. For this:
- your current directory must be a julia project root directory
  (a folder containing a `Project.toml`, a `Manifest.toml` and a `src/`).
- you must be authenticated so that `docker push <image-tag>` will
  push to a docker image registry acessible to your k8s cluster
  (for example for AWS ECR, this is done by ensuring that the
  [credential helper](https://github.com/awslabs/amazon-ecr-credential-helper)
  is installed and Docker is configured to use it).
- if you have a GitHub token that gives access to private github
  repositories, you can provide that secret by storing it in a file and
  specifying the path in the environment variable: `GITHUB_TOKEN_FILE`.

If you do not have a `Dockerfile` or `driver.yaml.template`
in your julia project root dir, default versions of these will be
copied over. At this point, you may want to take a look at both of
these files and edit them, remembering that `driver.yaml.template`
has comments indicating what not to touch;
in particular, it has `$ALLCAPS` strings that will be replaced
with runtime values when running `julia_pod`.

The first time, and every time you modify your project deps, this will 
take some time--building and pushing the docker image can take a while,
especially if sysimages are involved. However:
- subsequently it's fairly quick to spin up.
- you can add deps from within your julia session, and the folder 
  syncing will mirror them to your local project folder.

##### Examples

From a julia project folder containing Pluto as a dependency,

```bash
julia_pod --port-forward=1234:1234 'using Pluto; Pluto.run()'
```

will run a Pluto notebook and make `localhost:1234` forward to port
`1234` in the pod running the notebook.

`julia_pod --julia='"julia", "-t", "16"'` will launch a `julia_pod` with 16 threads.

### private package registry

If you use a private Julia packages you can add your private package
registry by setting the environmental variable `PRIVATE_REGISTRY_URL`.
The environmental variable `GITHUB_TOKEN_FILE` specifies path to the
credentials file used when authenticating.


### set your project up for faster load times

The default `Dockerfile` used by `julia_pod` is set up to
`PackageCompiler.jl` a sysimage for your package to minimize the
time it takes to `using MyProject` your project.

The convention for inclusion into the sysimage is that any
project dependency that is **pinned** included,
unless it is blacklisted as a package known not to work with
`PackageCompiler.jl`. To add the dependency `Example` to the
sysimage, in a julia REPL `Pkg` mode, do `]pin Example`.
Pinned packages show with a little ⚲ next to them when listed
with `]status`.

This convention came about because the package manager `Pkg.jl`
is not aware of what dependencies are included in the sysimage
(they are treated as un-versioned dependencies as though they
were part of the Julia stdlib, and always take precedence over
whatever dependencies `Pkg.jl` thinks it has added to the
project). Pinning the packages that are included in the sysimage 
ensures that the package versions used by `Pkg.jl` are fixed 
and cannot be accidentally changed. Without pinning a user
could change the version of a package via Pkg but find that they
are still only using the version locked into the sysimage.
This is why it was decided to use pinned packages to control
what is built into the sysimage.


##### notebooks

Pluto and ijulia notebooks work from `julia_pod` sessions, as long as:
- you have not passed in `--no-sync`, otherwise your notebook saves will
  not be reflected locally and will be lost when the pod dies
- you are port-forwarding from your pet instance to the pod by doing

```bash
driver=`ls driver-*.yaml | tail -n 1 | cut -d '.' -f 1`
kubectl port-forward pods/$driver 1234:1234 -n project-foo
```

This grabs the pod name from the last `driver-*.yaml` file written to 
the current directory (`julia_pod` writes a new one for each pod launch)
and forwards local port 1234 to the pod's 1234 port.

(Note that you may also need to port forward from your local
machine to the machine you are running `julia_pod` from,
if those are not one and the same;
traffic will then be passing through both port forwarding hops.)

### what it does

`julia_pod` will:
- copy over `add_me_to_your_PATH/{Dockerfile.template,sysimage.jl,driver.yaml.template}`
  to the project root dir if those files are absent
- ask you if you want to `$EDITOR driver.yaml.template`, to for example
  request a GPU or other resources
- compute a descriptive docker image tag of the form
`${GIT_REPO}_${GIT_BRANCH}_commit-${GIT_COMMIT}_sha1-${PROJECT_ROOTDIR}`
- build the docker image
- push it to our ECR
- launch a k8s job containing a single container in a single pod,
  with descriptive names
- drop you into a julia REPL with the current dir activated 
  as the julia project (default Dockerfile uses a sysimage),
  or if a (single) arg `julia_pod '...'` is passed in, runs the 
  corresponding command
- `devspace sync` your local julia project and `~/.julia/logs` dirs
  with the corresponding folders in the running container (unless 
  `--no-sync` was passed to `julia_pod`)

The default docker build is optimized for large julia projects that
take a long time to precompile and that use CUDA. In particular it 
is structured in 4 build stages:
- `base` contains julia + CUDA
- `sysimage-image` contains a sysimage built from your julia project in such
  a way as to minimize cache invalidation (only dependencies that
  will go into the sysimage make it into this build stage)
- `precompile-image` COPYs in `src/` and `dev/` and precompiles
- `project` sets up the final image
The build is structured this way so that subsequent builds can use
docker layers cached locally, or absent those, use layers from
these stages cached in the remote docker repository. The first
build might take some time, but subsequent invocations of `julia_pod`
from the same julia project should take  less than ~20 seconds.
