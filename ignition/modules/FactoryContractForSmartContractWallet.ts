import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

export default buildModule("FactoryContractForSmartContractWalletModule", (m) => {
  const factoryContractForSmartContractWallet = m.contract("FactoryContractForSmartContractWallet");
  return { factoryContractForSmartContractWallet };
});
