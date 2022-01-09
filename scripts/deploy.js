const main = async () => {
	const gameContractFactory = await hre.ethers.getContractFactory("MyEpicGame");
	const gameContract = await gameContractFactory.deploy(
		['жизнь хороша', 'РЯДОВОЙ', 'Sir_Willy', 'Tadakatsu HONDA', 'grisha', 'WLADGOROD', 'Восставший из АДА','Синдзи'], // names
		[
		'https://mineland.net/roma/lokha.png',
		'https://mineland.net/roma/krutovoy.png',
		'https://mineland.net/roma/willy.png',
		'https://mineland.net/roma/honda.png',
		'https://mineland.net/roma/grisha.png',
		'https://mineland.net/roma/wg.png',
		'https://mineland.net/roma/sir.png',
		'https://mineland.net/roma/sindzi.jpg'
		], // images
		[100500, 100, 1, 200, 120, 250, 80, 66], // hp
		[10, 10, 5, 15, 40, 50, 500, 66], // attack
		// BOSS
		'Gabe Newell',
		'https://mineland.net/roma/gabe.jpeg',
		5000, // hp
		35, // attack
	);


	await gameContract.deployed();
	console.log("Contract deployed to: ", gameContract.address);

	console.log("Done deploying!");
}

const runMain = async () => {
	try {
		await main();
		process.exit(0);
	} catch (error) {
		console.log(error);
		process.exit(1);
	}
}

runMain();