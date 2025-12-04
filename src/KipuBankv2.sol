// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract KipuBankv2 is Ownable(msg.sender), ReentrancyGuard {
    using SafeERC20 for IERC20;
    
    // Saldo de ETH por endereço
    mapping(address => uint256) public balances;
    
    // Saldo de tokens ERC20 por token e por endereço
    // tokenAddress => userAddress => balance
    mapping(address => mapping(address => uint256)) public tokenBalances;
    
    uint256 internal depositLimit;
    uint256 internal transactionsLimit;

    uint256 internal counterDeposit;
    uint256 internal counterWithdraw;


    error DepositLimitExceeded(uint256 depositLimit, uint256 deposited);
    error TransactionsLimitExceeded(uint256 transactionsLimit, uint256 transactions);
    error InsufficientBalance(uint256 balance, uint256 needed);
    error InvalidAmount(uint256 amount);
    error InvalidAddress(address _address);
    error InvalidSender(address sender);
    error InvalidReceiver(address receiver);
    error InvalidApprover(address approver);
    error FailedWithdraw(uint256 amount);
    error FailedTokenTransfer(address token, uint256 amount);

    event Deposit(address indexed sender, uint256 amount);
    event Withdraw(address indexed sender, uint256 amount);
    event DepositToken(address indexed sender, address indexed token, uint256 amount);
    event WithdrawToken(address indexed sender, address indexed token, uint256 amount);

    modifier amountNotZero(uint256 amount) {
        _amountNotZero(amount);
        _;
    }

    modifier addressNotZero(address _address) {
        _addressNotZero(_address);
        _;
    }
    
    modifier contractLimitNotExceeded(uint256 amount) {
        _contractBalanceNotExceeded(amount);
        _;
    }

    modifier transactionsLimitNotExceeded(uint256 amount) {
        _transactionsLimitNotExceeded(amount);
        _;
    }
    
    modifier balanceNotExceeded(uint256 amount) {
        _balanceNotExceeded(amount);
        _;
    }
    
    constructor(uint256 _depositLimit, uint256 _transactionsLimit) {
        depositLimit = _depositLimit;
        transactionsLimit = _transactionsLimit;
    }

    function deposit() public payable
        amountNotZero(msg.value)
        addressNotZero(msg.sender)
        contractLimitNotExceeded(depositLimit)
        transactionsLimitNotExceeded(msg.value)
        nonReentrant
     {
        counterDeposit++;
        balances[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    function withdraw(uint256 amount) public
        onlyOwner
        amountNotZero(amount)
        addressNotZero(msg.sender)
        balanceNotExceeded(amount)
        nonReentrant
        
    {
        counterWithdraw++;
        balances[msg.sender] -= amount;
        (bool success,) = (msg.sender).call{ value: amount }("");
        if (!success) revert FailedWithdraw(amount);

        emit Withdraw(msg.sender, amount);
    }

    function depositToken(address token, uint256 amount) public
        amountNotZero(amount)
        addressNotZero(msg.sender)
        addressNotZero(token)
        transactionsLimitNotExceeded(amount)
        nonReentrant
    {
        IERC20 tokenContract = IERC20(token);
        
        // Verifica se o contrato tem tokens suficientes depositados
        uint256 contractTokenBalance = tokenContract.balanceOf(address(this));
        if (contractTokenBalance + amount > depositLimit) {
            revert DepositLimitExceeded(depositLimit, contractTokenBalance + amount);
        }
        
        // Transfere tokens do usuário para o contrato
        tokenContract.safeTransferFrom(msg.sender, address(this), amount);
        
        // Atualiza o saldo do usuário
        tokenBalances[token][msg.sender] += amount;
        
        emit DepositToken(msg.sender, token, amount);
    }

   
    function withdrawToken(address token, uint256 amount) public
        onlyOwner
        amountNotZero(amount)
        addressNotZero(msg.sender)
        addressNotZero(token)
        nonReentrant
    {
        IERC20 tokenContract = IERC20(token);
        
        // Verifica se o usuário tem saldo suficiente
        if (tokenBalances[token][msg.sender] < amount) {
            revert InsufficientBalance(tokenBalances[token][msg.sender], amount);
        }
    
        // Atualiza o saldo antes de transferir (padrão checks-effects-interactions)
        tokenBalances[token][msg.sender] -= amount;
        
        // Transfere tokens do contrato para o usuário
        tokenContract.safeTransfer(msg.sender, amount);
        
        emit WithdrawToken(msg.sender, token, amount);
    }

   
    function getTokenBalance(address token, address user) public view returns (uint256) {
        return tokenBalances[token][user];
    }

    
    function getContractTokenBalance(address token) public view returns (uint256) {
        return IERC20(token).balanceOf(address(this));
    }

    function _amountNotZero(uint256 amount) internal view {
        if (amount == 0) revert InvalidAmount(amount);
    }

    function _addressNotZero(address _address) internal view {
        if (_address == address(0)) revert InvalidAddress(_address);
    }

    function _contractBalanceNotExceeded(uint256 amount) internal view {
        if (address(this).balance >= amount) revert DepositLimitExceeded(amount, address(this).balance);
    }
    
    function _transactionsLimitNotExceeded(uint256 amount) internal view {
        if (amount > transactionsLimit) revert TransactionsLimitExceeded(transactionsLimit, amount);
    }

    function _balanceNotExceeded(uint256 amount) internal view {
        if (balances[msg.sender] < amount) revert InsufficientBalance(balances[msg.sender], amount);
    }

    function getDepositLimit() public view returns (uint256) {
        return depositLimit;
    }

    function getTransactionsLimit() public view returns (uint256) {
        return transactionsLimit;
    }

    function getCounterDeposit() public view returns (uint256) {
        return counterDeposit;
    }

    function getCounterWithdraw() public view returns (uint256) {
        return counterWithdraw;
    }

    function getBalance(address _address) public view returns (uint256) {
        return balances[_address];
    }

    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function getOwner() public view returns (address) {
        return owner();
    }
}