module faas3::faas_nft {
    use sui::url::{Self, Url};
    use std::string::{Self, String};
    use sui::object::{Self, ID, UID};
    use sui::event;
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};

    struct FaaSNFT has key, store {
        id: UID,

        name: String,
        description: String,
        url: Url,
        content: String,
    }

    struct NFTMinted has copy, drop {
        object_id: ID,
        creator: address,
        name: string::String,
    }

    public entry fun mint(
        name: vector<u8>,
        description: vector<u8>,
        url: vector<u8>,
        content: vector<u8>,
        ctx: &mut TxContext
    ) {
        let nft = FaaSNFT {
            id: object::new(ctx),
            name: string::utf8(name),
            description: string::utf8(description),
            url: url::new_unsafe_from_bytes(url),
            content: string::utf8(content),
        };

        let sender = tx_context::sender(ctx);
        event::emit(NFTMinted {
            object_id: object::id(&nft),
            creator: sender,
            name: nft.name,
        });
        transfer::transfer(nft, sender);
    }

    public entry fun burn(nft: FaaSNFT) {
        let FaaSNFT { id, name: _, description: _, url: _, content: _ } = nft;
        object::delete(id)
    }

    public entry fun update_description(
        nft: &mut FaaSNFT,
        new_description: vector<u8>
    ) {
        nft.description = string::utf8(new_description)
    }

    public entry fun update_content(
        nft: &mut FaaSNFT,
        new_content: vector<u8>
    ) {
        nft.content = string::utf8(new_content)
    }

    public fun name(nft: &FaaSNFT): &String {
        &nft.name
    }

    public fun description(nft: &FaaSNFT): &String {
        &nft.description
    }

    public fun url(nft: &FaaSNFT): &Url {
        &nft.url
    }

    public fun content(nft: &FaaSNFT): &String {
        &nft.content
    }
}

#[test_only]
module faas3::faas_nftTests {
    use faas3::faas_nft::{Self, FaaSNFT};
    use sui::test_scenario as ts;
    use std::string;

    #[test]
    fun mint_transfer_update() {
        let addr1 = @0xA;

        let scenario = ts::begin(addr1);
        {
            faas_nft::mint(
                b"test",
                b"a test",
                b"https://www.sui.io",
                b"console.log(1)",
                ts::ctx(&mut scenario)
            )
        };

        ts::next_tx(&mut scenario, addr1);
        {
            let nft = ts::take_from_sender<FaaSNFT>(&mut scenario);
            faas_nft::update_description(&mut nft, b"a new description");
            assert!(
                *string::bytes(faas_nft::description(&nft)) == b"a new description",
                0
            );
            ts::return_to_sender(&mut scenario, nft);
        };

        ts::next_tx(&mut scenario, addr1);
        {
            let nft = ts::take_from_sender<FaaSNFT>(&mut scenario);
            faas_nft::burn(nft)
        };
        ts::end(scenario);
    }
}

