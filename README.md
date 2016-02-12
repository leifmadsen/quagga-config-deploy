# quagga-config-deploy
Deploy quagga configurations for OSP-d lab. These templates and playbooks are
used in an OSP-d deployment where a layer 3 networking fabric is used. The
data here may be generic enough for you to use outside of an OpenStack
deployment but some additional changes may be required.

Not intended for production. Just playing around in the lab.

# Usage
Playbooks were tested with Ansible 1.9.4. Sorry that I didn't convert this
stuff into separate roles and then consume them.

General steps are:

* run `geninv.sh` to generate the inventory files
* run an initial `bootstrap.yaml` that creates a management network
* run the `site.yaml` to deploy all the things

## Generate inventory files
Start by generating the `bootstrap` and `inventory` files against your newly
minted OpenStack environment. It is assumed this is run from the undercloud and
that you've sources the `stackrc` file so that `nova list` is avalable to you.
Additionally, it's assumed that you can ssh to the hosts via `heat-admin`.

```shell
./geninv.sh
```

## Run the bootstrap
The bootstrap will go and create a new sub interface against your
`local_interface` that was determined in the `geninv.sh` run. The results of
this can be found in the `bootstrap` inventory file. The network that is
created will be the same local network found on the local interface, but with
the second octet increased by one. For example: 10.16.0.0 will become 10.17.0.0
where you can SSH into.

We do this because the existing IP addresses allocated to the interface during
the OSP-d deployment will get moved to the layer 3 fabric.

```shell
ansible-playbook -i bootstrap bootstrap.yaml
```

## Deploy all the things
Now we get to have some fun. The `site.yaml` will go and configure the
interfaces, deploy Quagga, and then configure `zebra.conf` and `bgpd.conf`. The
information and values are fairly biased to my deployment in the lab, but I've
tried to make some of the information dynamic. Again, this isn't really
intended to be used outside my environment.

Defaults for interfaces are provided at the top of the `site.yaml` but you can
override these with a JSON file that you pass to `--extra-vars`. Example below.

```shell
ansible-playbook -i inventory site.yaml
```

Pass a new list of interfaces to override the default ones.

> **Note**: Of course you can also limit things with a `--limit` if you don't
> want to run through the whole inventory.

```shell
ansible-playbook -i inventory --extra-vars "../bgp-ints.json" site.yaml
```
