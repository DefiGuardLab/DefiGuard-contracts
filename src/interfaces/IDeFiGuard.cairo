use defiguard::DeFiGuard::DeFiGuard::{CoverPosition, Protocol};
use starknet::ContractAddress;

#[starknet::interface]
pub trait IDeFiGuard<TContractState> {
    // Protocol Management
    fn create_pool(
        ref self: TContractState,
        protocol_name: felt252,
        risk_score: u8,
        cover_amount: u256,
        premium_rate: u256,
    ) -> bool;

    fn add_protocol(ref self: TContractState, protocol_name: felt252, risk_score: u8) -> bool;

    // Cover Management
    fn buy_cover(
        ref self: TContractState, protocol_name: felt252, cover_amount: u256, cover_duration: u64,
    ) -> bool;

    fn claim_cover(ref self: TContractState, protocol_name: felt252, claim_amount: u256) -> bool;

    fn validate_protocol_name(ref self: TContractState, protocol_name: felt252) -> bool;

    // View Functions
    fn get_protocols(ref self: TContractState) -> Array<felt252>;
    fn get_protocol_details(ref self: TContractState, protocol_name: felt252) -> Protocol;
    fn get_user_cover(ref self: TContractState, user: ContractAddress) -> Array<CoverPosition>;
    fn get_total_liquidity(ref self: TContractState) -> u256;
}
