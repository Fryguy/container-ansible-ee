With ansible-runner:

```sh
ansible-runner run ~/dev/test/ansible-ee/dir --ident result --playbook subdir/test_localhost.yml
```

With ansible-navigator:

```sh
cd dir/project
ansible-navigator run subdir/test_localhost.yml --execution-environment-image ghcr.io/ansible-community/community-ee-base:latest --mode stdout --pull-policy missing
```

