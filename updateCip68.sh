#!/bin/bash

# Cap quyen chay chmod +x 06-update_NFT_CIP_68_v2.sh
# Dừng script ngay khi có lỗi
set -e

# Bắt lỗi và in thông tin chi tiết
trap 'echo "==> Lỗi tại dòng $LINENO"; exit 1' ERR

#
#-------------------- Phan khai bao cho NFT -------------------
#

# Khai bao dia chi nguoi gui , dia chi nguoi nhan, ten token, so luong token tạo
token_name="Bai2"
token_hex=$(echo -n $token_name | xxd -p | tr -d '\n')

# IPFS hash cho metadata, có thể là bất kỳ hash nào bạn muốn
ipfs_hash="ipfs://Qmc2u9RsjizhLthmpwCtyUCigG8g5jXACZKTa8gqvFLSnp"
ipfs_hash_hex=$(echo -n "$ipfs_hash" | xxd -p | tr -d '\n')

echo "Starting script, 05-minting NFT CIP-68 $token_name"

mkdir -p mint-$token_name
cd mint-$token_name

#
#-------------------- Phan khai cho nguoi nhan va nguoi gui -------------------
#

sender="addr_test1qqftxx64wa84u6f6kp4jm8meql7kmz25x8jn8l05eyzpdfwjp3p4rmnr904yawqgp9aqyz4tlhxpf2m9l6hlxe3e4ljspq3jn8"
sender_key="/home/admin1/do1/rv2/LS3/A.skey"
ADA_amount=8000047

receiver_addr=addr_test1qpuexzns2ze8g5csu30mnnk6gf2vx3kpwz2vcgvjsv7q3dr4mvw6eahqha5vj295mm0ugphljpesxaszfcff5hq9w63qrh0623
# cardano-cli query utxo --address $(cat alice.addr) --testnet-magic 2

#
#-------------------------Phan xay dung giao dich-----------------------
#

# Khai bao policy id
policy_id=$(cat $token_name.txt)

# Tao fle datum để gắn vào reference NFT
echo "{" > update_datum.json
echo "  \"constructor\": 0," >> update_datum.json
echo "  \"fields\": [" >> update_datum.json
echo "    {" >> update_datum.json
echo "      \"map\": [" >> update_datum.json
echo "        {" >> update_datum.json
echo "          \"k\": { \"bytes\": \"6e616d65\" }," >> update_datum.json
echo "          \"v\": { \"bytes\": \"$token_hex\" }" >> update_datum.json
echo "        }," >> update_datum.json
echo "        {" >> update_datum.json
echo "          \"k\": { \"bytes\": \"696d616765\" }," >> update_datum.json
echo "          \"v\": { \"bytes\": \"$ipfs_hash_hex\" }" >> update_datum.json
echo "        }," >> update_datum.json
echo "        {" >> update_datum.json
echo "          \"k\": { \"bytes\": \"6465736372697074696f6e\" }," >> update_datum.json
echo "          \"v\": { \"bytes\": \"$(echo -n 'datum has been updated' | xxd -p | tr -d '\n')\" }" >> update_datum.json
echo "        }" >> update_datum.json
echo "      ]" >> update_datum.json
echo "    }," >> update_datum.json
echo "    { \"int\": 1 }" >> update_datum.json
echo "  ]" >> update_datum.json
echo "}" >> update_datum.json


# Query UTXO và lưu tất cả UTXO vào file utxos.json
cardano-cli query utxo --address $sender --testnet-magic 2 --out-file utxos.json
# Lấy UTXO có số lượng ADA lớn hơn ADA_amount
tx_in=$(jq -r "to_entries[] | select(.value.value.lovelace > ($ADA_amount+1000000)) | \"\(.key)\"" utxos.json | head -n 1)
# Kiểm tra xem có UTXO nào phù hợp không
if [ -z "$tx_in" ]; then
    echo "No suitable UTXO found with sufficient ADA amount."
    exit 1
else
    echo "Found UTXO: $tx_in"
fi


echo "Start building transaction to send native assets..."
# Build Tx
cardano-cli conway transaction build \
    --testnet-magic 2 \
    --tx-in $tx_in \
    --tx-in 1a7e5c24f3d48d4afd640d480d7a0a429703326ad3d4078a947b3380626ce313#1 \
    --tx-out $receiver_addr+$ADA_amount+"1 $policy_id.000643b0$token_hex" \
    --tx-out-datum-embed-file update_datum.json \
    --change-address $sender \
    --out-file update-NFT.build \

echo "Create Transaction draft created: update-NFT.build"
# Sign Tx
cardano-cli conway transaction sign \
    --testnet-magic 2 \
    --signing-key-file $sender_key \
    --tx-body-file update-NFT.build \
    --out-file update-NFT.signed

echo "Transaction signed..."

# Submit Tx
cardano-cli conway transaction submit \
    --testnet-magic 2 \
    --tx-file update-NFT.signed

echo "End script !"