#!/usr/bin/env bats

# Tests for the ManageIQ Ansible Execution Environment
# These tests verify the EE image builds correctly and runs playbooks as expected.

export BATS_LIB_PATH="$HOME/.bats/libs:$BATS_LIB_PATH"

bats_load_library 'bats-support'
bats_load_library 'bats-assert'

# Global variables
EE_IMAGE="${EE_IMAGE:-docker.io/manageiq/ansible-ee:latest}"
ARCH=${ARCH:=$(uname -m | sed 's/x86_64/amd64/')}
DATA_DIR="${BATS_TEST_DIRNAME}/data"

setup_file() {
  # Check if the EE image exists; if not, skip tests with a message
  if ! docker image inspect "${EE_IMAGE}" >/dev/null 2>&1; then
    echo "${EE_IMAGE} not found. Build it first with 'bin/build_container_image' or set EE_IMAGE to an existing image." >&3
    skip "EE image not available"
  fi
}

setup() {
  # Populate the ansible-runner project directory with all test data
  cp -r "${DATA_DIR}/." "${BATS_TEST_TMPDIR}/project"
}

exec_ee_raw() {
  # Usage: exec_ee_raw [KEY=VAL...] -- <container command...>
  # Runs the EE image with the runner dir mounted, optional env vars, and the given command.
  local -a env_args=()
  while [[ "$1" == *=* ]]; do
    env_args+=(-e "$1"); shift
  done
  [[ "$1" == "--" ]] && shift
  run docker run --rm --platform=linux/${ARCH} \
    -v "${BATS_TEST_TMPDIR}:/runner" \
    "${env_args[@]}" \
    "${EE_IMAGE}" \
    "$@"
}

exec_ee() {
  # Usage: exec_ee [KEY=VAL...] <playbook>
  local playbook="${@: -1}"
  exec_ee_raw "${@:1:$#-1}" -- \
    ansible-runner run /runner --ident result --playbook "${playbook}"
}

exec_ee_with_galaxy() {
  # Usage: exec_ee_with_galaxy [KEY=VAL...] <requirements_file> <roles_install_path> <playbook>
  local playbook="${@: -1}" roles_path="${@: -2:1}" requirements="${@: -3:1}"
  exec_ee_raw "${@:1:$#-3}" -- \
    sh -c "ansible-galaxy install -r ${requirements} -p ${roles_path} && ansible-runner run /runner --ident result --playbook ${playbook}"
}

exec_ee_role() {
  # Usage: exec_ee_role [KEY=VAL...] <role>
  local role="${@: -1}"
  exec_ee_raw "${@:1:$#-1}" -- \
    ansible-runner run /runner --ident result --role "${role}" --roles-path /runner/roles --role-skip-facts --hosts localhost
}

exec_ee_role_with_galaxy() {
  # Usage: exec_ee_role_with_galaxy [KEY=VAL...] <requirements_file> <role>
  local role="${@: -1}" requirements="${@: -2:1}"
  exec_ee_raw "${@:1:$#-2}" -- \
    sh -c "ansible-galaxy install -r ${requirements} -p /runner/roles && ansible-runner run /runner --ident result --role ${role} --roles-path /runner/roles --role-skip-facts --hosts localhost"
}

################################################################################
# Playbook execution tests
################################################################################

@test "runs a playbook" {
  exec_ee hello_world.yml
  assert_success
  assert_output --partial '"msg": "Hello World!"'
}

@test "runs a playbook with variables in a vars file" {
  exec_ee hello_world_vars_file.yml
  assert_success
  assert_output --partial '"msg": "Hello World! vars_file_1=vars_file_1_value, vars_file_2=vars_file_2_value"'
}

@test "runs a playbook with vault encrypted variables" {
  mkdir -p "${BATS_TEST_TMPDIR}/env"
  echo -n "vault" > "${BATS_TEST_TMPDIR}/env/vault_password"
  exec_ee ANSIBLE_VAULT_PASSWORD_FILE=/runner/env/vault_password hello_world_vault_encrypted_vars.yml
  assert_success
  assert_output --partial '"msg": "Hello World! (NOTE: This message has been encrypted with ansible-vault)"'
}

@test "runs a playbook with variables in a vault encrypted vars file" {
  mkdir -p "${BATS_TEST_TMPDIR}/env"
  echo -n "vault" > "${BATS_TEST_TMPDIR}/env/vault_password"
  exec_ee ANSIBLE_VAULT_PASSWORD_FILE=/runner/env/vault_password hello_world_vault_encrypted_vars_file.yml
  assert_success
  assert_output --partial '"msg": "Hello World! vars_file_1=vars_file_1_value, vars_file_2=vars_file_2_value"'
}

@test "runs a playbook using roles from github" {
  exec_ee_with_galaxy \
    /runner/project/hello_world_with_requirements_github/roles/requirements.yml \
    /runner/project/hello_world_with_requirements_github/roles \
    hello_world_with_requirements_github/hello_world_with_requirements_github.yml
  assert_success
  assert_output --partial '"msg": "Hello World! example_var='\''example var value'\''"'
}

@test "runs a role" {
  exec_ee_role_with_galaxy /runner/project/hello_world_with_requirements_github/roles/requirements.yml manageiq.example
  assert_success
  assert_output --partial '"msg": "Hello from manageiq.example role! example_var='\''example var value'\''"'
}

@test "vmware collection" {
  exec_ee vmware.yml
  assert_failure # We expect to this to fail due to connecting to an unknown vcenter
  assert_output --partial '"msg": "Unknown error while connecting to the vCenter or ESXi API at vcenter_hostname:443 : [Errno -'
}

@test "aws collection" {
  exec_ee aws.yml
  assert_failure # We expect to this to fail due to connecting with bad creds
  assert_output --partial '"msg": "Failed to describe instances: An error occurred (AuthFailure) when calling the DescribeInstances operation: AWS was not able to validate the provided access credentials"'
}

################################################################################
# Image configuration tests
################################################################################

@test "has required ManageIQ roles installed" {
  run docker run --rm --platform=linux/${ARCH} "${EE_IMAGE}" ansible-galaxy role list
  assert_success
  assert_output --partial "manageiq.manageiq_automate"
  assert_output --partial "manageiq.manageiq_vmdb"
}

@test "ansible.cfg suppresses python interpreter warning" {
  exec_ee hello_world.yml
  assert_success
  refute_output --regexp "\[WARNING\].*interpreter"
}

@test "output is colorized by default" {
  exec_ee hello_world.yml
  assert_success
  assert_output --partial $'\e['
}

@test "output color can be disabled with ANSIBLE_FORCE_COLOR=0" {
  exec_ee ANSIBLE_FORCE_COLOR=0 hello_world.yml
  assert_success
  refute_output --partial $'\e['
}
