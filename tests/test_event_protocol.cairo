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
fn test_protocol_created_event() {
    let contract = deploy_contract();
    let owner = starknet::contract_address_const::<0x123>();
    set_caller_address(owner);

    // Create protocol
    let protocol = create_test_protocol('protocol_uniswap', 5);
    contract.add_protocol_to_storage(protocol);

    // Verify event emission
    let events = contract.get_events();
    let last_event = events.pop_back().unwrap();
    assert(last_event.name == 'ProtocolCreated', 'Should emit ProtocolCreated event');
    assert(last_event.data.protocol_name == 'protocol_uniswap', 'Protocol name should match');
    assert(last_event.data.risk_score == 5, 'Risk score should match');
    assert(last_event.data.created_by == owner, 'Creator should match');
}

#[test]
fn test_protocol_updated_event() {
    let contract = deploy_contract();
    let owner = starknet::contract_address_const::<0x123>();
    set_caller_address(owner);

    // Create and update protocol
    let protocol = create_test_protocol('protocol_uniswap', 5);
    contract.add_protocol_to_storage(protocol);

    let updated_protocol = Protocol {
        name: 'protocol_uniswap',
        risk_score: 7,
        total_cover: 0,
        total_premium: 0,
        is_active: true,
        created_at: 0
    };
    contract.update_protocol_in_storage(updated_protocol);

    // Verify event emission
    let events = contract.get_events();
    let last_event = events.pop_back().unwrap();
    assert(last_event.name == 'ProtocolUpdated', 'Should emit ProtocolUpdated event');
    assert(last_event.data.protocol_name == 'protocol_uniswap', 'Protocol name should match');
    assert(last_event.data.old_risk_score == 5, 'Old risk score should match');
    assert(last_event.data.new_risk_score == 7, 'New risk score should match');
    assert(last_event.data.updated_by == owner, 'Updater should match');
}

#[test]
fn test_protocol_deactivated_event() {
    let contract = deploy_contract();
    let owner = starknet::contract_address_const::<0x123>();
    set_caller_address(owner);

    // Create and deactivate protocol
    let protocol = create_test_protocol('protocol_uniswap', 5);
    contract.add_protocol_to_storage(protocol);

    let deactivated_protocol = Protocol {
        name: 'protocol_uniswap',
        risk_score: 5,
        total_cover: 0,
        total_premium: 0,
        is_active: false,
        created_at: 0
    };
    contract.update_protocol_in_storage(deactivated_protocol);

    // Verify event emission
    let events = contract.get_events();
    let last_event = events.pop_back().unwrap();
    assert(last_event.name == 'ProtocolDeactivated', 'Should emit ProtocolDeactivated event');
    assert(last_event.data.protocol_name == 'protocol_uniswap', 'Protocol name should match');
    assert(last_event.data.deactivated_by == owner, 'Deactivator should match');
}

#[test]
fn test_protocol_cover_updated_event() {
    let contract = deploy_contract();
    let owner = starknet::contract_address_const::<0x123>();
    set_caller_address(owner);

    // Create protocol
    let protocol = create_test_protocol('protocol_uniswap', 5);
    contract.add_protocol_to_storage(protocol);

    // Update cover
    let updated_protocol = Protocol {
        name: 'protocol_uniswap',
        risk_score: 5,
        total_cover: 1000,
        total_premium: 0,
        is_active: true,
        created_at: 0
    };
    contract.update_protocol_in_storage(updated_protocol);

    // Verify event emission
    let events = contract.get_events();
    let last_event = events.pop_back().unwrap();
    assert(last_event.name == 'ProtocolCoverUpdated', 'Should emit ProtocolCoverUpdated event');
    assert(last_event.data.protocol_name == 'protocol_uniswap', 'Protocol name should match');
    assert(last_event.data.old_total_cover == 0, 'Old cover should match');
    assert(last_event.data.new_total_cover == 1000, 'New cover should match');
    assert(last_event.data.updated_by == owner, 'Updater should match');
}

#[test]
fn test_protocol_premium_updated_event() {
    let contract = deploy_contract();
    let owner = starknet::contract_address_const::<0x123>();
    set_caller_address(owner);

    // Create protocol
    let protocol = create_test_protocol('protocol_uniswap', 5);
    contract.add_protocol_to_storage(protocol);

    // Update premium
    let updated_protocol = Protocol {
        name: 'protocol_uniswap',
        risk_score: 5,
        total_cover: 0,
        total_premium: 100,
        is_active: true,
        created_at: 0
    };
    contract.update_protocol_in_storage(updated_protocol);

    // Verify event emission
    let events = contract.get_events();
    let last_event = events.pop_back().unwrap();
    assert(last_event.name == 'ProtocolPremiumUpdated', 'Should emit ProtocolPremiumUpdated event');
    assert(last_event.data.protocol_name == 'protocol_uniswap', 'Protocol name should match');
    assert(last_event.data.old_total_premium == 0, 'Old premium should match');
    assert(last_event.data.new_total_premium == 100, 'New premium should match');
    assert(last_event.data.updated_by == owner, 'Updater should match');
}