# Yo! CorDapp

Send Yo's! to all your friends running Corda nodes!


## Concepts

In the original yo application, the app sent what is essentially a nudge from one endpoint and another.

In corda, we can use abstractions to accomplish the same thing.


We define a state (the yo to be shared), define a contract (the way to make sure the yo is legit), and define the flow (the control flow of our cordapp).

### States
We define a [Yo as a state](./contracts/src/main/java/net/corda/examples/yo/states/YoState.java#L31-L35), or a corda fact.

```java
    public YoState(Party origin, Party target) {
        this.origin = origin;
        this.target = target;
        this.yo = "Yo!";
    }
```


### Contracts
We define [the "Yo Social Contract"](./contracts/src/main/java/net/corda/examples/yo/contracts/YoContract.java#L21-L32), which, in this case, verifies some basic assumptions about a Yo.

```java
    @Override
    public void verify(@NotNull LedgerTransaction tx) throws IllegalArgumentException {
        CommandWithParties<Commands.Send> command = requireSingleCommand(tx.getCommands(), Commands.Send.class);
        requireThat(req -> {
            req.using("There can be no inputs when Yo'ing other parties", tx.getInputs().isEmpty());
            req.using("There must be one output: The Yo!", tx.getOutputs().size() == 1);
            YoState yo = tx.outputsOfType(YoState.class).get(0);
            req.using("No sending Yo's to yourself!", !yo.getTarget().equals(yo.getOrigin()));
            req.using("The Yo! must be signed by the sender.", command.getSigners().contains(yo.getOrigin().getOwningKey()));
            return null;
        });
    }

```


### Flows
And then we send the Yo [within a flow](./workflows/src/main/java/net/corda/examples/yo/flows/YoFlow.java#L59-L64).

```java
        Party me = getOurIdentity();
        Party notary = getServiceHub().getNetworkMapCache().getNotaryIdentities().get(0);
        Command<YoContract.Commands.Send> command = new Command<YoContract.Commands.Send>(new YoContract.Commands.Send(), ImmutableList.of(me.getOwningKey()));
        YoState state = new YoState(me, target);
        StateAndContract stateAndContract = new StateAndContract(state, YoContract.ID);
        TransactionBuilder utx = new TransactionBuilder(notary).withItems(stateAndContract, command);
```

On the receiving end, the other corda node will simply receive the Yo using corda provided subroutines, or subflows.

```java
    return subFlow(new ReceiveFinalityFlow(counterpartySession));
```


## Usage

### Quick Start with Docker

If  you have docker installed you can use our gradle tasks to generate a valid docker compose file for your node configuration.

```bash
# clone the repository
git clone https://github.com/davidawad/corda-docker-yo-demo && cd corda-docker-yo-demo

# generate the docker-compose file
./gradlew prepareDockerNodes

# run our corda network
docker-compose -f ./build/nodes/docker-compose.yml up
```

#### Sending a Yo

We will interact with the nodes via their specific shells. When the nodes are up and running, use the following command to send a Yo to another node:

```sh
# find the ssh port for PartyA using docker ps
ssh user1@0.0.0.0 -p 2223

# the password defined in the node config for PartyA is "test"
Password: test


Welcome to the Corda interactive shell.
You can see the available commands by typing 'help'.

# you'll see the corda shell available
Fri May 15 18:23:03 GMT 2020>>> flow start YoFlow target: PartyB

```

Where `NODE_NAME` is 'PartyA' or 'PartyB'. The space after the `:` is required. You are not required to use the full X500 name in the node shell.

###### Note you can't sent a Yo! to yourself because that's not cool!

To see all the Yo's! other nodes have sent you in your vault you can run a vault query from the Corda shell:

```bash
run vaultQuery contractStateType: net.corda.examples.yo.states.YoState
```
