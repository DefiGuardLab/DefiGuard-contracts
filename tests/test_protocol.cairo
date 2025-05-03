use debug::PrintTrait;
use array::ArrayTrait;
use option::OptionTrait;
use traits::TryInto;
use starknet::ContractAddress;
use starknet::testing::{set_caller_address, start_prank, stop_prank};
use defiguard::DeFiGuard::DeFiGuard::{Protocol, CoverPosition, ProtocolError};

fn deploy_contract() -> ContractAddress {
    let owner = starknet::contract_address_const::<0x123>();
    let contract = DeFiGuard::deploy(@owner);
    contract
}

fn create_test_protocol(name: felt252, risk_score: u8) -> Protocol {
    Protocol {
        name,
        risk_score,
        total_cover: 0,
        total_premium: 0,
        is_active: true,
        created_at: 0
    }
}

#[test]
fn test_add_protocol_to_storage() {
    let contract = deploy_contract();
    let owner = starknet::contract_address_const::<0x123>();
    set_caller_address(owner);

    // Add protocol
    let protocol = create_test_protocol('protocol_uniswap', 5);
    let result = contract.add_protocol_to_storage(protocol);
    assert(result == true, 'Should successfully add protocol');

    // Verify storage
    let stored_protocol = contract.protocols.read('protocol_uniswap');
    assert(stored_protocol.name == 'protocol_uniswap', 'Protocol name should match');
    assert(stored_protocol.risk_score == 5, 'Risk score should match');
    assert(contract.get_protocol_count() == 1, 'Protocol count should be 1');
    assert(contract.get_active_protocol_count() == 1, 'Active protocol count should be 1');
}

#[test]
fn test_update_protocol_in_storage() {
    let contract = deploy_contract();
    let owner = starknet::contract_address_const::<0x123>();
    set_caller_address(owner);

    // Add protocol
    let protocol = create_test_protocol('protocol_uniswap', 5);
    contract.add_protocol_to_storage(protocol);

    // Update protocol
    let updated_protocol = Protocol {
        name: 'protocol_uniswap',
        risk_score: 7,
        total_cover: 1000,
        total_premium: 100,
        is_active: true,
        created_at: 0
    };
    let result = contract.update_protocol_in_storage(updated_protocol);
    assert(result == true, 'Should successfully update protocol');

    // Verify storage
    let stored_protocol = contract.protocols.read('protocol_uniswap');
    assert(stored_protocol.risk_score == 7, 'Risk score should be updated');
    assert(stored_protocol.total_cover == 1000, 'Total cover should be updated');
    assert(stored_protocol.total_premium == 100, 'Total premium should be updated');
}

#[test]
fn test_remove_protocol_from_storage() {
    let contract = deploy_contract();
    let owner = starknet::contract_address_const::<0x123>();
    set_caller_address(owner);

    // Add protocols
    let protocol1 = create_test_protocol('protocol_uniswap', 5);
    let protocol2 = create_test_protocol('protocol_aave', 6);
    contract.add_protocol_to_storage(protocol1);
    contract.add_protocol_to_storage(protocol2);

    // Remove first protocol
    let result = contract.remove_protocol_from_storage('protocol_uniswap');
    assert(result == true, 'Should successfully remove protocol');

    // Verify storage
    assert(contract.get_protocol_count() == 1, 'Protocol count should be 1');
    assert(contract.get_active_protocol_count() == 1, 'Active protocol count should be 1');
    
    // Verify protocol list is updated
    let remaining_protocol = contract.get_protocol_by_index(0);
    assert(remaining_protocol.name == 'protocol_aave', 'Remaining protocol should be Aave');
}

#[test]
fn test_get_protocol_by_index() {
    let contract = deploy_contract();
    let owner = starknet::contract_address_const::<0x123>();
    set_caller_address(owner);

    // Add protocols
    let protocol1 = create_test_protocol('protocol_uniswap', 5);
    let protocol2 = create_test_protocol('protocol_aave', 6);
    contract.add_protocol_to_storage(protocol1);
    contract.add_protocol_to_storage(protocol2);

    // Get protocols by index
    let first_protocol = contract.get_protocol_by_index(0);
    let second_protocol = contract.get_protocol_by_index(1);

    assert(first_protocol.name == 'protocol_uniswap', 'First protocol should be Uniswap');
    assert(second_protocol.name == 'protocol_aave', 'Second protocol should be Aave');
}

#[test]
fn test_protocol_count_management() {
    let contract = deploy_contract();
    let owner = starknet::contract_address_const::<0x123>();
    set_caller_address(owner);

    // Add protocols
    let protocol1 = create_test_protocol('protocol_uniswap', 5);
    let protocol2 = create_test_protocol('protocol_aave', 6);
    contract.add_protocol_to_storage(protocol1);
    contract.add_protocol_to_storage(protocol2);

    // Verify counts
    assert(contract.get_protocol_count() == 2, 'Total protocol count should be 2');
    assert(contract.get_active_protocol_count() == 2, 'Active protocol count should be 2');

    // Deactivate one protocol
    let updated_protocol = Protocol {
        name: 'protocol_uniswap',
        risk_score: 5,
        total_cover: 0,
        total_premium: 0,
        is_active: false,
        created_at: 0
    };
    contract.update_protocol_in_storage(updated_protocol);

    // Verify updated counts
    assert(contract.get_protocol_count() == 2, 'Total protocol count should still be 2');
    assert(contract.get_active_protocol_count() == 1, 'Active protocol count should be 1');
} 