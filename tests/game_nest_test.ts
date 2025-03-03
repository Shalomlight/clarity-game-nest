Clarinet.test({
  name: "Can manage community treasury with proper token transfer",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;
    const wallet1 = accounts.get('wallet_1')!;
    
    // Create community
    let block = chain.mineBlock([
      Tx.contractCall('game-nest', 'create-community', [
        types.ascii("TestGame Community"),
        types.ascii("A community for TestGame players")
      ], deployer.address)
    ]);
    
    // Deposit to treasury with STX transfer
    let depositBlock = chain.mineBlock([
      Tx.contractCall('game-nest', 'deposit-to-treasury', [
        types.uint(0),
        types.uint(1000)
      ], deployer.address)
    ]);
    
    depositBlock.receipts[0].result.expectOk().expectBool(true);
    
    // Verify treasury balance and STX transfer
    let getInfo = chain.callReadOnlyFn(
      'game-nest',
      'get-community-info',
      [types.uint(0)],
      deployer.address
    );
    
    let communityInfo = getInfo.result.expectOk().expectSome();
    assertEquals(communityInfo['treasury-balance'], 1000);
    
    // Verify member points update
    let memberInfo = chain.callReadOnlyFn(
      'game-nest',
      'get-member-info',
      [types.uint(0), types.principal(deployer.address)],
      deployer.address
    );
    
    let memberData = memberInfo.result.expectOk().expectSome();
    assertEquals(memberData['points'], 10);
  },
});
