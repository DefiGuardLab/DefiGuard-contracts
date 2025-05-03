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
fn test_validate_risk_score_success() {
    let contract = deploy_contract();
    let owner = starknet::contract_address_const::<0x123>();
    set_caller_address(owner);

    // Test valid risk score
    let valid_risk_score = 5;
    let result = contract.validate_risk_score(valid_risk_score);
    assert(result == true, 'Should return true for valid risk score');
}

#[test]
fn test_validate_risk_score_too_low() {
    let contract = deploy_contract();
    let owner = starknet::contract_address_const::<0x123>();
    set_caller_address(owner);

    // Test too low risk score
    let low_risk_score = 0;
    let result = contract.validate_risk_score(low_risk_score);
    assert(result == false, 'Should return false for too low risk score');
}

#[test]
fn test_validate_risk_score_too_high() {
    let contract = deploy_contract();
    let owner = starknet::contract_address_const::<0x123>();
    set_caller_address(owner);

    // Test too high risk score
    let high_risk_score = 11;
    let result = contract.validate_risk_score(high_risk_score);
    assert(result == false, 'Should return false for too high risk score');
}

#[test]
fn test_validate_risk_score_unauthorized() {
    let contract = deploy_contract();
    let non_owner = starknet::contract_address_const::<0x456>();
    set_caller_address(non_owner);

    // Test unauthorized access
    let valid_risk_score = 5;
    let mut success = false;
    match contract.validate_risk_score(valid_risk_score) {
        Ok(_) => {},
        Err(_) => { success = true; },
    }
    assert(success, 'Should fail for unauthorized access');
}

#[test]
fn test_update_protocol_risk_score() {
    let contract = deploy_contract();
    let owner = starknet::contract_address_const::<0x123>();
    set_caller_address(owner);

    // First add a protocol
    let protocol_name = 'protocol_uniswap';
    let initial_risk_score = 5;
    let protocol = Protocol {
        name: protocol_name,
        risk_score: initial_risk_score,
        total_cover: 0,
        total_premium: 0,
        is_active: true,
        created_at: 0,
    };
    contract.protocols.write(protocol_name, protocol);

    // Update risk score
    let new_risk_score = 7;
    let result = contract.update_protocol_risk_score(protocol_name, new_risk_score);
    assert(result == true, 'Should successfully update risk score');

    // Verify update
    let updated_protocol = contract.protocols.read(protocol_name);
    assert(updated_protocol.risk_score == new_risk_score, 'Risk score should be updated');
}

#[test]
fn test_update_nonexistent_protocol() {
    let contract = deploy_contract();
    let owner = starknet::contract_address_const::<0x123>();
    set_caller_address(owner);

    // Try to update non-existent protocol
    let protocol_name = 'protocol_nonexistent';
    let new_risk_score = 7;
    let mut success = false;
    match contract.update_protocol_risk_score(protocol_name, new_risk_score) {
        Ok(_) => {},
        Err(_) => { success = true; },
    }
    assert(success, 'Should fail for non-existent protocol');
}
