//SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./BPool.sol";
import "./WETH9.sol";
import "./Registry.sol";

contract MyDexV2 is Initializable {
    using SafeMath for uint256;
    address recipient;
    IUniswapV2Router02 uniV2;
    BPool bPool;
    WETH9 weth;
    Registry registry;

    function initialize(address _recipient) public initializer {
        recipient = _recipient;
        uniV2 = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    }

    function Swap(uint256[] memory _percentages, address[] memory _addresses)
        public
        payable
        setValid(_percentages, _addresses)
    {
        weth = WETH9(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
        registry = Registry(0x7226DaaF09B3972320Db05f5aB81FF38417Dd687);
        address[] memory path = new address[](2);
        path[0] = uniV2.WETH();

        //Value of eth to send to the recipient
        uint256 send = (msg.value).div(1000);

        //Rest of the eth to work with
        uint256 rest = (msg.value).sub(send);

        //Looking for the tokens swap
        for (uint256 i = 0; i < _percentages.length; i++) {
            path[1] = _addresses[i];

            //Amount of eth we going to use for the trade
            uint256 total = (_percentages[i].mul(rest)).div(100);

            // Uniswap
            uint256[] memory uniswap_tokens = uniV2.getAmountsOut(total, path);

            //Balancer
            address getInstancePool =
                registry.getBestPoolsWithLimit(
                    0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2,
                    path[1],
                    1
                )[0];
            bPool = BPool(getInstancePool);
            uint256 balancer_price =
                bPool.getSpotPrice(
                    0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2,
                    path[1]
                );
            uint256 balancer_tokens = total.div(balancer_price);

            //Compare and swap
            if (uniswap_tokens[0] >= balancer_tokens) {
                uniV2.swapExactETHForTokens{value: total}(
                    uniswap_tokens[0],
                    path,
                    msg.sender,
                    block.timestamp + 3600
                );
            } else {
                weth.deposit{value: total}();
                weth.approve(getInstancePool, total);

                (uint256 tokenAmountOut, uint256 spotPriceAfter) =
                    bPool.swapExactAmountIn(
                        0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2,
                        total,
                        path[1],
                        balancer_tokens,
                        balancer_price.mul(110).div(100)
                    );
                ERC20(path[1]).transfer(msg.sender, tokenAmountOut);
            }
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
