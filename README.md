
Our CI infrastructure is built around [BuildKite](https://buildkite.com) with some
additional GitHub integration provided by https://github.com/mvines/ci-gate

## Agent Queues

We define two [Agent Queues](https://buildkite.com/docs/agent/v3/queues):
`queue=default` and `queue=cuda`.  The `default` queue should be favored and
runs on lower-cost CPU instances.  The `cuda` queue is only necessary for
running **tests** that depend on GPU (via CUDA) access -- CUDA builds may still
be run on the `default` queue, and the [buildkite artifact
system](https://buildkite.com/docs/builds/artifacts) used to transfer build
products over to a GPU instance for testing.

## Buildkite Agent Management

### Buildkite GCP Setup

CI runs on Google Cloud Platform via two Compute Engine Instance groups:
`ci-default` and `ci-cuda`.  Autoscaling is currently disabled and the number of
VM Instances in each group is manually adjusted.

#### Updating a CI Disk Image

Each Instance group has its own disk image, `ci-default-vX` and
`ci-cuda-vY`, where *X* and *Y* are incremented each time the image is changed.

The process to update a disk image is as follows (TODO: make this less manual):

1. Create a new VM Instance using the disk image to modify.
2. Once the VM boots, ssh to it and modify the disk as desired.
3. Stop the VM Instance running the modified disk.  Remember the name of the VM disk
4. From another machine, `gcloud auth login`, then create a new Disk Image based
off the modified VM Instance:
```
 $ gcloud compute images create ci-default-$(date +%Y%m%d) --source-disk xxx --source-disk-zone us-east1-b --family ci-default

```
or
```
  $ gcloud compute images create ci-cuda-$(date +%Y%m%d) --source-disk xxx --source-disk-zone us-east1-b --family ci-cuda
```
5. Delete the new VM instance.
6. Go to the Instance templates tab, find the existing template named
`ci-default-vX` or `ci-cuda-vY` and select it.  Use the "Copy" button to create
a new Instance template called `ci-default-vX+1` or `ci-cuda-vY+1` with the
newly created Disk image.
7. Go to the Instance Groups tag and find the applicable group, `ci-default` or
`ci-cuda`.  Edit the Instance Group in two steps: (a) Set the number of
instances to 0 and wait for them all to terminate, (b) Update the Instance
template and restore the number of instances to the original value.
8. Clean up the previous version by deleting it from Instance Templates and
Images. 


## Reference

### Buildkite AWS CloudFormation Setup

**AWS CloudFormation is currently inactive, although it may be restored in the
future**

AWS CloudFormation can be used to scale machines up and down based on the
current CI load.  If no machine is currently running it can take up to 60
seconds to spin up a new instance, please remain calm during this time.

#### AMI
We use a custom AWS AMI built via https://github.com/solana-labs/elastic-ci-stack-for-aws/tree/solana/cuda.

Use the following process to update this AMI as dependencies change:
```bash
$ export AWS_ACCESS_KEY_ID=my_access_key
$ export AWS_SECRET_ACCESS_KEY=my_secret_access_key
$ git clone https://github.com/solana-labs/elastic-ci-stack-for-aws.git -b solana/cuda
$ cd elastic-ci-stack-for-aws/
$ make build
$ make build-ami
```

Watch for the *"amazon-ebs: AMI:"* log message to extract the name of the new
AMI.  For example:
```
amazon-ebs: AMI: ami-07118545e8b4ce6dc
```
The new AMI should also now be visible in your EC2 Dashboard.  Go to the desired
AWS CloudFormation stack, update the **ImageId** field to the new AMI id, and
*apply* the stack changes.


