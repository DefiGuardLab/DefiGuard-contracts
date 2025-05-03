use array::ArrayTrait;
use debug::PrintTrait;
use defiguard::DeFiGuard::DeFiGuard::{CoverPosition, Protocol, ProtocolError};
use option::OptionTrait;
use starknet::ContractAddress;
use starknet::testing::{set_caller_address, start_prank, stop_prank};
use traits::TryInto;

fn deploy_contract() -> ContractAddress {
    let owner = starknet::contract_address_const::<0x123>();
    let contract = DeFiGuard::deploy(@owner);
    contract
}

#[test]
fn test_validate_protocol_name_success() {
    let contract = deploy_contract();
    let owner = starknet::contract_address_const::<0x123>();
    set_caller_address(owner);

    // Test valid protocol name
    let valid_name = 'protocol_uniswap';
    let result = contract.validate_protocol_name(valid_name);
    assert(result == true, 'Should return true for valid name');
}

#[test]
fn test_validate_protocol_name_too_short() {
    let contract = deploy_contract();
    let owner = starknet::contract_address_const::<0x123>();
    set_caller_address(owner);

    // Test too short name
    let short_name = 'pr';
    let result = contract.validate_protocol_name(short_name);
    assert(result == false, 'Should return false for too short name');
}

#[test]
fn test_validate_protocol_name_too_long() {
    let contract = deploy_contract();
    let owner = starknet::contract_address_const::<0x123>();
    set_caller_address(owner);

    // Test too long name
    let long_name = 'protocol_this_name_is_way_too_long_for_a_protocol_name';
    let result = contract.validate_protocol_name(long_name);
    assert(result == false, 'Should return false for too long name');
}

#[test]
fn test_validate_protocol_name_invalid_format() {
    let contract = deploy_contract();
    let owner = starknet::contract_address_const::<0x123>();
    set_caller_address(owner);

    // Test invalid format (missing prefix)
    let invalid_name = 'uniswap';
    let result = contract.validate_protocol_name(invalid_name);
    assert(result == false, 'Should return false for invalid format');
}

#[test]
fn test_validate_protocol_name_unauthorized() {
    let contract = deploy_contract();
    let non_owner = starknet::contract_address_const::<0x456>();
    set_caller_address(non_owner);

    // Test unauthorized access
    let valid_name = 'protocol_uniswap';
    let mut success = false;
    match contract.validate_protocol_name(valid_name) {
        Ok(_) => {},
        Err(_) => { success = true; },
    }
    assert(success, 'Should fail for unauthorized access');
}

#[test]
fn test_validate_protocol_name_duplicate() {
    let contract = deploy_contract();
    let owner = starknet::contract_address_const::<0x123>();
    set_caller_address(owner);

    // First add a protocol
    let protocol_name = 'protocol_uniswap';
    let protocol = Protocol {
        name: protocol_name,
        risk_score: 5,
        total_cover: 0,
        total_premium: 0,
        is_active: true,
        created_at: 0,
    };
    contract.protocols.write(protocol_name, protocol);

    // Try to validate the same name
    let result = contract.validate_protocol_name(protocol_name);
    assert(result == false, 'Should return false for duplicate name');
}
