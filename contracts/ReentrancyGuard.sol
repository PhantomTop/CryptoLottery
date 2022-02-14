// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity 0.8.7;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;
    uint256 private _statusBuyTicketLevel1;
    uint256 private _statusBuyTicketLevel2;
    uint256 private _statusBuyTicketLevel3;
    uint256 private _statusBuyTicketLevel4;
    uint256 private _statusBuyTicketLevel5;
    uint256 private _statusBuyTicketLevel6;
    uint256 private _statusWhoIsWinner;
    uint256 private _statusWinnerGetPrize;

    constructor() {
        _status = _NOT_ENTERED;
        _statusBuyTicketLevel1 = _NOT_ENTERED;
        _statusBuyTicketLevel2 = _NOT_ENTERED;
        _statusBuyTicketLevel3 = _NOT_ENTERED;
        _statusBuyTicketLevel4 = _NOT_ENTERED;
        _statusBuyTicketLevel5 = _NOT_ENTERED;
        _statusBuyTicketLevel6 = _NOT_ENTERED;
        _statusWhoIsWinner = _NOT_ENTERED;
        _statusWinnerGetPrize = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    modifier nonReentrantBuyTicketLevel1() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_statusBuyTicketLevel1 != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _statusBuyTicketLevel1 = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _statusBuyTicketLevel1 = _NOT_ENTERED;
    }

    modifier nonReentrantBuyTicketLevel2() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_statusBuyTicketLevel2 != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _statusBuyTicketLevel2 = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _statusBuyTicketLevel2 = _NOT_ENTERED;
    }

    modifier nonReentrantBuyTicketLevel3() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_statusBuyTicketLevel3 != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _statusBuyTicketLevel3 = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _statusBuyTicketLevel3 = _NOT_ENTERED;
    }

    modifier nonReentrantBuyTicketLevel4() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_statusBuyTicketLevel4 != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _statusBuyTicketLevel4 = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _statusBuyTicketLevel4 = _NOT_ENTERED;
    }

    modifier nonReentrantBuyTicketLevel5() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_statusBuyTicketLevel5 != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _statusBuyTicketLevel5 = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _statusBuyTicketLevel5 = _NOT_ENTERED;
    }

    modifier nonReentrantBuyTicketLevel6() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_statusBuyTicketLevel6 != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _statusBuyTicketLevel6 = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _statusBuyTicketLevel6 = _NOT_ENTERED;
    }

    modifier nonReentrantWhoIsWinner() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_statusWhoIsWinner != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _statusWhoIsWinner = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _statusWhoIsWinner = _NOT_ENTERED;
    }

    modifier nonReentrantWinnerGetPrize() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_statusWinnerGetPrize != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _statusWinnerGetPrize = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _statusWinnerGetPrize = _NOT_ENTERED;
    }
}
