# RWA Tranche Protocol (Web3 Structured Finance)

![License](https://img.shields.io/badge/License-MIT-green)
![Network](https://img.shields.io/badge/Network-Sepolia_Testnet-blue)
![Language](https://img.shields.io/badge/Language-Solidity_%7C_JavaScript-orange)

## 📖 Project Overview
**RWA Tranche Protocol** is a decentralized application (DApp) that implements **Structured Finance** logic on the Ethereum blockchain. It tokenizes the cash flows of Real World Assets (RWA) and redistributes them through a **Waterfall Payment Model**, creating risk-stratified investment opportunities.

This project serves as a Proof of Concept (PoC) for bridging traditional financial engineering with decentralized ledger technology (DLT).

---

## 🚀 Live Demo
**Try the DApp here:** [Launch RWA Tranche Protocol](https://jieao0720-debug.github.io/rwa-tranche-protocol/)

> *Note: Requires MetaMask connected to Sepolia Testnet.*

---

## 📊 Financial Logic: The Waterfall Model

The protocol splits the underlying asset pool into two tranches with distinct risk-return profiles:

```graph TD
    A[Underlying Asset Yield] --> B{Waterfall Distributor}
    B -- Priority Payment --> C[Senior Tranche]
    B -- Residual Payment --> D[Junior Tranche]
    
    C -.-> E["Fixed APY (5%)"]
    C -.-> F["Low Risk / First Claim"]
    
    D -.-> G["Excess Returns (Float)"]
    D -.-> H["High Risk / First Loss"]
