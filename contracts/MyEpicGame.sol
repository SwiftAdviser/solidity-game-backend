// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

// Helper functions OpenZeppelin provides.
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "hardhat/console.sol";
import './libraries/Base64.sol';


contract MyEpicGame is ERC721 {

	struct CharacterAttributes {
		uint characterIndex;
		string name;
		string imageURI;
		uint hp;
		uint maxHp;
		uint attackDamage;
		
		uint respawnTime;
		uint respawnIn;

	}

	using Counters for Counters.Counter;
	Counters.Counter private _tokenIds;

	CharacterAttributes[] defaultCharacters;
	struct BigBoss {
		string name;
		string imageURI;
		uint hp;
		uint maxHp;
		uint attackDamage;
	}

	BigBoss public bigBoss;

	// player's nft
	mapping(uint256 => CharacterAttributes) public nftHoldersAttributes;
	// address => nft's token id
	mapping(address => uint256) public nftHolders;

	constructor(
		string[] memory characterNames,
		string[] memory characterImageURIs,
		uint[] memory characterHp,
		uint[] memory characterAttackDmg,
		string memory bossName,
		string memory bossImageURI,
		uint bossHp,
		uint bossAttackDamage
		) ERC721("CS GO HEROES", "HERO") {

		bigBoss = BigBoss({
			name: bossName,
			imageURI: bossImageURI,
			hp: bossHp,
			maxHp: bossHp,
			attackDamage: bossAttackDamage
			});

		console.log("Done init boss %s w/ HP %s, img %s", bigBoss.name, bigBoss.hp, bigBoss.imageURI);

		for (uint i = 0; i < characterNames.length; i += 1) {
			defaultCharacters.push(CharacterAttributes({
					characterIndex: i,
					name: characterNames[i],
					imageURI: characterImageURIs[i],
					hp: characterHp[i],
					maxHp: characterHp[i],
					attackDamage: characterAttackDmg[i],
					respawnTime: 60,
					respawnIn: 0
				}));

			CharacterAttributes memory c = defaultCharacters[i];
			console.log("Done initializing %s w/ HP %s, img %s", c.name, c.hp, c.imageURI);
		}

		_tokenIds.increment();

	}

	/**
	 * Mint your NFT
	 */
	function mintCharacterNFT(uint _characterIndex) external {
		uint256 newItemId = _tokenIds.current();


		_safeMint(msg.sender, newItemId);

		nftHoldersAttributes[newItemId] = CharacterAttributes({
			characterIndex: _characterIndex,
			name: defaultCharacters[_characterIndex].name,
			imageURI: defaultCharacters[_characterIndex].imageURI,
			hp: defaultCharacters[_characterIndex].hp,
			maxHp: defaultCharacters[_characterIndex].maxHp,
			attackDamage: defaultCharacters[_characterIndex].attackDamage,
			respawnTime: defaultCharacters[_characterIndex].respawnTime,
			respawnIn: defaultCharacters[_characterIndex].respawnIn
		});

		console.log("Minted NFT w/ tokenId %s and characterIndex %s", newItemId, _characterIndex);

		nftHolders[msg.sender] = newItemId;

		_tokenIds.increment();

		emit CharacterNFTMinted(msg.sender, newItemId, _characterIndex);
	}

	function tokenURI(uint256 _tokenId) public view override returns (string memory) {
		CharacterAttributes memory charAttributes = nftHoldersAttributes[_tokenId];

		string memory strHp = Strings.toString(charAttributes.hp);
		string memory strMaxHp = Strings.toString(charAttributes.maxHp);
		string memory strAttachDamage = Strings.toString(charAttributes.attackDamage);
		string memory strRespawn = Strings.toString(charAttributes.respawnTime);

		string memory json = Base64.encode(
			abi.encodePacked(
				'{"name": "',
				charAttributes.name,
				' -- NFT #: ',
				Strings.toString(_tokenId),
				'", "description": "This is an NFT that lets people play in the game CS GO HEROES!", "image":"',
				charAttributes.imageURI,
				'", "attributes": ',
				'[ { "trait_type": "Health Points", "value": ', strHp,', "max_value": ', strMaxHp,'},',
				' {"trait_type": "Attack Damage", "value": ', strAttachDamage,'},',
				' {"trait_type": "Respawn Time (seconds)", "value": ', strRespawn,'}',
				']}'
			));

		string memory output = string(
			abi.encodePacked("data:application/json;base64,", json)
		);

		return output;
	}

	function attackBoss() public {
		uint256 nftTokenIdOfPlayer = nftHolders[msg.sender];
		CharacterAttributes storage player = nftHoldersAttributes[nftTokenIdOfPlayer];

		console.log("\nPlayer w/ character %s about to attack. Has %s HP and %s AD", player.name, player.hp, player.attackDamage);
		console.log("Boss %s has %s HP and %s AD", bigBoss.name, bigBoss.hp, bigBoss.attackDamage);	


		require(
			player.respawnIn < block.timestamp,
			"Error: player should be alive!"
			);

		require(
			player.hp > 0,
			"Error: character must have HP to attack Boss!"
			);

		require(
			bigBoss.hp > 0,
			"Error: boss must have hp to attack boss"
			);

		if (bigBoss.hp < player.attackDamage) {
			bigBoss.hp = 0;
		} else {
			bigBoss.hp = bigBoss.hp - player.attackDamage;
		}

		if (player.hp < bigBoss.attackDamage) {
			player.hp = 0;

			player.respawnIn = block.timestamp + player.respawnTime;
			// ХОЧУ УМНОЖАТЬ АТАКУ В 2 РАЗА ПОСЛЕ СМЕРТИ
			player.attackDamage = player.attackDamage * 2;
		} else {
			player.hp = player.hp - bigBoss.attackDamage;
		}
		
		console.log("Player attacked boss. New boss hp: %s", bigBoss.hp);
		console.log("Boss attacked player. New player hp: %s\n", player.hp);

		emit AttackComplete(bigBoss.hp, player.hp, player.respawnIn);
	}

	function checkIfUserHasNFT() public view returns (CharacterAttributes memory) {
		uint256 userNFTTokenId = nftHolders[msg.sender];

		if (userNFTTokenId > 0) {
			return nftHoldersAttributes[userNFTTokenId];
		} else {
			CharacterAttributes memory emptyStruct;
			return emptyStruct;
		}
	}

	function getAllDefaultCharacters() public view returns (CharacterAttributes[] memory) {
		return defaultCharacters;
	}

	function getBoss() public view returns (BigBoss memory) {
		return bigBoss;
	}

	event CharacterNFTMinted(address sender, uint256 tokenId, uint256 characterIndex);
	event AttackComplete(uint newBossHp, uint newPlayerHp, uint respawnIn);


}