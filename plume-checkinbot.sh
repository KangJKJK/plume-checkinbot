#!/bin/bash

# 파란색 굵은 텍스트를 출력하는 함수 정의
function echo_blue_bold {
    echo -e "\033[1;34m$1\033[0m"
}
echo

# privatekeys.txt 파일이 존재하지 않는 경우 오류 메시지를 출력하고 스크립트 종료
if [ ! -f privatekeys.txt ]; then
  echo_blue_bold "오류: privatekeys.txt 파일을 찾을 수 없습니다!"
  exit 1
fi

# ethers 패키지가 설치되어 있지 않으면 설치, 이미 설치되어 있으면 메시지 출력
if ! npm list ethers@5.5.4 >/dev/null 2>&1; then
  echo_blue_bold "ethers 패키지를 설치 중..."
  npm install ethers@5.5.4
  echo
else
  echo_blue_bold "ethers 패키지가 이미 설치되어 있습니다."
fi
echo

# 임시 Node.js 스크립트 파일 생성
temp_node_file=$(mktemp /tmp/node_script.XXXXXX.js)

# Node.js 스크립트 내용을 임시 파일에 작성
cat << EOF > $temp_node_file
const fs = require("fs");
const ethers = require("ethers");

// privatekeys.txt 파일에서 개인 키를 읽어와 줄바꿈을 기준으로 배열로 저장
const privateKeys = fs.readFileSync("privatekeys.txt", "utf8").trim().split("\\n");

// 이더리움 공급자 URL 설정
const providerURL = "https://testnet-rpc.plumenetwork.xyz/http";
const provider = new ethers.providers.JsonRpcProvider(providerURL);

// 스마트 계약 주소 및 트랜잭션 데이터 설정
const contractAddress = "0x8Dc5b3f1CcC75604710d9F464e3C5D2dfCAb60d8";
const transactionData = "0x183ff085";
const numberOfTransactions = 1;  // 보낼 트랜잭션 수 설정

// 트랜잭션을 보내는 비동기 함수 정의
async function sendTransaction(wallet) {
    const tx = {
        to: contractAddress,  // 스마트 계약 주소로 트랜잭션 전송
        value: 0,             // 전송할 이더리움 값 (0으로 설정)
        gasLimit: ethers.BigNumber.from(600000),  // 가스 리미트 설정
        gasPrice: ethers.utils.parseUnits("0.3", 'gwei'),  // 가스 가격 설정
        data: transactionData,  // 트랜잭션 데이터 설정
    };

    try {
        // 트랜잭션 전송 및 결과 대기
        const transactionResponse = await wallet.sendTransaction(tx);
        const walletAddress = wallet.address;
        console.log("\033[1;35m트랜잭션 해시:\033[0m", transactionResponse.hash);
        const receipt = await transactionResponse.wait();  // 트랜잭션 확인 대기
        console.log("");
    } catch (error) {
        console.error("트랜잭션 전송 중 오류 발생:", error);
    }
}

// 메인 비동기 함수 정의
async function main() {
    // 각 개인 키에 대해 트랜잭션을 전송
    for (const key of privateKeys) {
        const wallet = new ethers.Wallet(key, provider);
        for (let i = 0; i < numberOfTransactions; i++) {
            console.log("지갑에서 체크인 중:", wallet.address);
            await sendTransaction(wallet);  // 트랜잭션 전송
        }
    }
}

// 메인 함수 실행 및 오류 출력
main().catch(console.error);
EOF

# Node.js 스크립트 실행
NODE_PATH=$(npm root -g):$(pwd)/node_modules node $temp_node_file

# 임시 Node.js 스크립트 파일 삭제
rm $temp_node_file
echo

# 안내 메시지 출력
echo -e "${GREEN}모든 작업이 완료되었습니다.${NC}"
echo -e "${GREEN}스크립트작성자-https://t.me/kjkresearch${NC}"

