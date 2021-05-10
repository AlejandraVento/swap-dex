//SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MyDexV1 is Initializable {
    using SafeMath for uint256;
    address recipient;
    IUniswapV2Router02 uniV2;

    function initialize(address _recipient) public initializer {
        recipient = _recipient;
        uniV2 = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    }

    function Swap(uint256[] memory _percentages, address[] memory _addresses)
        public
        payable
        setValid(_percentages, _addresses)
    {
        address[] memory path = new address[](2);
        path[0] = uniV2.WETH();

        //Value of eth to send to the recipient
        uint256 send = ((msg.value)).div(1000);

        //Rest of the eth to work with
        uint256 rest = (msg.value).sub(send);

        //Looking for the tokens swap
        for (uint256 i = 0; i < _percentages.length; i++) {
            path[1] = _addresses[i];

            //Amount of eth we going to use for the trade
            uint256 total = (_percentages[i].mul(rest)).div(100);

            //Minimum amount of tokens
            uint256[] memory amountOutMin = uniV2.getAmountsOut(total, path);

            //Swap
            uniV2.swapExactETHForTokens{value: total}(
                amountOutMin[1],
                path,
                msg.sender,
                block.timestamp + 3600
            );
        }
        //Transfer recipient
        payable(recipient).transfer(send);
    }

    modifier setValid(
        uint256[] memory _percentages,
        address[] memory _addresses
    ) {
        require(_percentages.length == _addresses.length);
        require(msg.value > 0);

        uint256 higher = 0;

        for (uint256 i = 0; i < _percentages.length; i++) {
            higher += _percentages[i];
        }

        require(higher == 100);
        _;
    }
}
