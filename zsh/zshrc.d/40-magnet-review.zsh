# Magnet Review / AWS / ECR helpers (ported from EC2 .zshrc)

export AWS_PROFILE="${AWS_PROFILE:-dev_review}"

export REVIEW_WORKDIR="${REVIEW_WORKDIR:-$CODE_ROOT}"
export REVIEW_CONFIG_DIR="${REVIEW_CONFIG_DIR:-$CODE_ROOT/default_configs}"
export REVIEW_DEV_IMAGE="${REVIEW_DEV_IMAGE:-review_dotnet_dev_image}"
export REVIEW_FE_DEV_IMAGE="${REVIEW_FE_DEV_IMAGE:-review_fe_dev_image}"
export REVIEW_LOCAL_DEV_DIR="${REVIEW_LOCAL_DEV_DIR:-$CODE_ROOT/review-local-dev}"

REVIEW_BASH_EXTENSIONS="${REVIEW_BASH_EXTENSIONS:-$HOME/.review_bash_extensions}"
if [[ -d "$REVIEW_BASH_EXTENSIONS" ]]; then
  # shellcheck disable=SC1090
  [[ -f "$REVIEW_BASH_EXTENSIONS/base" ]] && source "$REVIEW_BASH_EXTENSIONS/base"
  for review_bashrc_file in "$REVIEW_BASH_EXTENSIONS"/*.bashrc(N); do
    # shellcheck disable=SC1090
    source "$review_bashrc_file"
  done
elif [[ -L "$HOME/.review_bash_extensions" || -d "$CODE_ROOT/magnet-review/scripts/bash_extensions" ]]; then
  # EC2 used a symlink into magnet-review; recreate that on WSL via link.sh / bootstrap.
  :
fi

export ECR="${ECR:-817772630816.dkr.ecr.ca-central-1.amazonaws.com}"
export PRDECR="${PRDECR:-894622485220.dkr.ecr.us-east-1.amazonaws.com}"
export STSECR="${STSECR:-644822186741.dkr.ecr.us-east-1.amazonaws.com}"
export EC2ECR="${EC2ECR:-602401143452.dkr.ecr.us-east-1.amazonaws.com}"

dotfiles_log "${Yellow}>AWS SSO LOGIN and attempting ECR + HELM login"

function awssso() {
  aws sso login --profile "${AWS_PROFILE:-dev_review}"
  AWS_REGION=ca-central-1 aws ecr get-login-password | docker login -u AWS --password-stdin "$ECR"
  AWS_REGION=ca-central-1 aws ecr get-login-password | helm registry login -u AWS --password-stdin "$ECR"
  AWS_REGION=us-east-1 aws ecr get-login-password | docker login -u AWS --password-stdin "$STSECR"
  AWS_REGION=us-east-1 aws ecr get-login-password | docker login -u AWS --password-stdin "$EC2ECR"
  AWS_REGION=us-east-1 aws ecr get-login-password | docker login -u AWS --password-stdin "$PRDECR"
}

dotfiles_log "${Yellow}>Registering Mirror function for ECR"

function image_to_prod() {
  if [[ -z "$1" ]]; then
    echo "Usage: image_to_prod <image-name>:<tag>"
    echo "Example: image_to_prod mr-auth-service:8948"
    return 1
  fi

  local IMAGE="$1"
  local SOURCE_IMAGE="${ECR}/${IMAGE}"
  local DEST_IMAGE="${PRDECR}/${IMAGE}"

  echo "Logging into Dev ECR (817772630816 - ca-central-1)..."
  aws ecr get-login-password --region ca-central-1 | docker login -u AWS --password-stdin "$ECR"

  echo "Pulling ${SOURCE_IMAGE}..."
  docker pull "$SOURCE_IMAGE" || return 1

  echo "Logging into Prod ECR (894622485220 - us-east-1)..."
  aws ecr get-login-password --region us-east-1 | docker login -u AWS --password-stdin "$PRDECR"

  echo "Retagging to ${DEST_IMAGE}..."
  docker tag "$SOURCE_IMAGE" "$DEST_IMAGE"

  echo "Pushing ${DEST_IMAGE}..."
  docker push "$DEST_IMAGE"

  echo "Cleaning up local images..."
  docker rmi "$SOURCE_IMAGE" "$DEST_IMAGE" 2>/dev/null

  echo "Done! Image mirrored to prod ECR successfully."
}

function kill_docker_fr_fr() {
  docker image ls -q | xargs -I {} docker image rm -f {}
}

# kubectl secret → mysql (needs cluster access)
function mysqllol() {
  local LOL_MYSQL_HOST LOL_MYSQL_PASS LOL_MYSQL_USER
  LOL_MYSQL_HOST=$(kubectl get secret -n magnet-review review-mysql-root -o jsonpath='{.data.MYSQL_HOST}' | base64 -d)
  LOL_MYSQL_PASS=$(kubectl get secret -n magnet-review review-mysql-root -o jsonpath='{.data.MYSQL_PASS}' | base64 -d)
  LOL_MYSQL_USER=$(kubectl get secret -n magnet-review review-mysql-root -o jsonpath='{.data.MYSQL_USER}' | base64 -d)
  mysql -h "$LOL_MYSQL_HOST" -u "$LOL_MYSQL_USER" -p"$LOL_MYSQL_PASS"
}

function tunnel_to_sd3() {
  ssh -i ~/.ssh/id_rsa -N -L 3307:eks-saas-dev-3-mysqlv2.cluster-cnquck3vx4qd.us-east-1.rds.amazonaws.com:3306 ubuntu@3.215.107.66
}

function tunnel_to_sd1() {
  ssh -i ~/.ssh/id_rsa -N -L 3307:eks-saas-dev-1-mysqlv2.cluster-cnquck3vx4qd.us-east-1.rds.amazonaws.com:3306 ubuntu@98.94.145.54
}

dotfiles_log "${Color_Off}"
