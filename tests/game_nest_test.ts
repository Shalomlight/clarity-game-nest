import {
  Clarinet,
  Tx,
  Chain,
  Account,
  types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
  name: "Can create a new gaming community",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;
    
    let block = chain.mineBlock([
      Tx.contractCall('game-nest', 'create-community', [
        types.ascii("TestGame Community"),
        types.ascii("A community for TestGame players")
      ], deployer.address)
    ]);
    
    // Check that community was created successfully
    block.receipts[0].result.expectOk().expectUint(0);
    
    // Verify community info
    let getInfo = chain.callReadOnlyFn(
      'game-nest',
      'get-community-info',
      [types.uint(0)],
      deployer.address
    );
    
    let communityInfo = getInfo.result.expectOk().expectSome();
    assertEquals(communityInfo.name, "TestGame Community");
  },
});

Clarinet.test({
  name: "Can join existing communities",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;
    const wallet1 = accounts.get('wallet_1')!;
    
    // First create a community
    let block = chain.mineBlock([
      Tx.contractCall('game-nest', 'create-community', [
        types.ascii("TestGame Community"),
        types.ascii("A community for TestGame players")
      ], deployer.address)
    ]);
    
    // Now try to join it
    let joinBlock = chain.mineBlock([
      Tx.contractCall('game-nest', 'join-community', [
        types.uint(0)
      ], wallet1.address)
    ]);
    
    joinBlock.receipts[0].result.expectOk().expectBool(true);
    
    // Verify membership
    let getMember = chain.callReadOnlyFn(
      'game-nest',
      'get-member-info',
      [types.uint(0), types.principal(wallet1.address)],
      deployer.address
    );
    
    let memberInfo = getMember.result.expectOk().expectSome();
    assertEquals(memberInfo.role, "member");
  },
});

Clarinet.test({
  name: "Can create and vote on proposals",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;
    const wallet1 = accounts.get('wallet_1')!;
    
    // Create community and join
    let setupBlock = chain.mineBlock([
      Tx.contractCall('game-nest', 'create-community', [
        types.ascii("TestGame Community"),
        types.ascii("A community for TestGame players")
      ], deployer.address),
      Tx.contractCall('game-nest', 'join-community', [
        types.uint(0)
      ], wallet1.address)
    ]);
    
    // Create proposal
    let proposalBlock = chain.mineBlock([
      Tx.contractCall('game-nest', 'create-proposal', [
        types.uint(0),
        types.ascii("Test Proposal"),
        types.ascii("This is a test proposal")
      ], deployer.address)
    ]);
    
    proposalBlock.receipts[0].result.expectOk().expectUint(0);
    
    // Vote on proposal
    let voteBlock = chain.mineBlock([
      Tx.contractCall('game-nest', 'vote-on-proposal', [
        types.uint(0),
        types.bool(true)
      ], wallet1.address)
    ]);
    
    voteBlock.receipts[0].result.expectOk().expectBool(true);
    
    // Verify proposal state
    let getProposal = chain.callReadOnlyFn(
      'game-nest',
      'get-proposal-info',
      [types.uint(0)],
      deployer.address
    );
    
    let proposalInfo = getProposal.result.expectOk().expectSome();
    assertEquals(proposalInfo['votes-for'], 1);
  },
});