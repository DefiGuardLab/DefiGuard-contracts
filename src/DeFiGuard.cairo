#[starknet::contract]
pub mod DeFiGuard {
    use starknet::storage::{Map, StorageMapWriteAccess, StoragePointerReadAccess, StorageMapReadAccess,StoragePointerWriteAccess};
    use starknet::{ContractAddress,get_caller_address};
    use core::array::ArrayTrait;
    use core::option::OptionTrait;

    // Constants for protocol name validation
    const MIN_PROTOCOL_NAME_LENGTH: u32 = 3;
    const MAX_PROTOCOL_NAME_LENGTH: u32 = 32;
    const PROTOCOL_NAME_PREFIX: felt252 = 'protocol_';

    // Constants for risk score validation
    const MIN_RISK_SCORE: u8 = 1;
    const MAX_RISK_SCORE: u8 = 10;
    const DEFAULT_RISK_SCORE: u8 = 5;

    // Custom errors
    #[derive(Drop, Debug, PartialEq, starknet::Store)]
    enum ProtocolError {
        #[default]
        NameTooShort,
        NameTooLong,
        NameAlreadyExists,
        InvalidNameFormat,
        Unauthorized,
        InvalidRiskScore,
        ProtocolNotFound
    }

    #[derive(Clone, Debug, Drop, PartialEq, Serde, starknet::Store)]
    pub struct Protocol {
        name: felt252,
        risk_score: u8,
        total_cover: u256,
        total_premium: u256,
        is_active: bool,
        created_at: u64
    }
    
    #[derive(Clone, Debug, Drop, PartialEq, Serde, starknet::Store)]
    pub struct CoverPosition {
        protocol_name: felt252,
        cover_amount: u256,
        premium_paid: u256,
        start_time: u64,
        end_time: u64,
        is_active: bool
    }

    #[storage]
    struct Storage {
        // Protocol storage
        protocols: Map::<felt252, Protocol>,
        protocol_list: Map::<u32, felt252>,
        protocol_count: u32,

        // User cover positions
        user_cover_positions: Map::<ContractAddress, Map::<felt252, CoverPosition>>,
        
        // Liquidity tracking
        total_liquidity: u256,
        
        // Access control
        owner: ContractAddress,
        is_initialized: bool
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        // Protocol Events
        ProtocolCreated: ProtocolCreated,
        ProtocolUpdated: ProtocolUpdated,
        ProtocolDeactivated: ProtocolDeactivated,
        ProtocolReactivated: ProtocolReactivated,
        ProtocolRemoved: ProtocolRemoved,
        ProtocolRiskUpdated: ProtocolRiskUpdated,
        ProtocolCoverUpdated: ProtocolCoverUpdated,
        ProtocolPremiumUpdated: ProtocolPremiumUpdated,
        ProtocolValidationFailed: ProtocolValidationFailed, // Added event
    }

    #[derive(Drop, starknet::Event)]
    struct ProtocolValidationFailed {
        protocol_name: felt252,
        error: felt252,
    }

    #[derive(Drop, starknet::Event)]
    struct ProtocolCreated {
        protocol_name: felt252,
        risk_score: u8,
        created_by: ContractAddress,
        timestamp: u64
    }

    #[derive(Drop, starknet::Event)]
    struct ProtocolUpdated {
        protocol_name: felt252,
        old_risk_score: u8,
        new_risk_score: u8,
        updated_by: ContractAddress,
        timestamp: u64
    }

    #[derive(Drop, starknet::Event)]
    struct ProtocolDeactivated {
        protocol_name: felt252,
        deactivated_by: ContractAddress,
        timestamp: u64,
        reason: felt252
    }

    #[derive(Drop, starknet::Event)]
    struct ProtocolReactivated {
        protocol_name: felt252,
        reactivated_by: ContractAddress,
        timestamp: u64
    }

    #[derive(Drop, starknet::Event)]
    struct ProtocolRemoved {
        protocol_name: felt252,
        removed_by: ContractAddress,
        timestamp: u64,
        reason: felt252
    }

    #[derive(Drop, starknet::Event)]
    struct ProtocolRiskUpdated {
        protocol_name: felt252,
        old_risk_score: u8,
        new_risk_score: u8,
        updated_by: ContractAddress,
        timestamp: u64,
        reason: felt252
    }

    #[derive(Drop, starknet::Event)]
    struct ProtocolCoverUpdated {
        protocol_name: felt252,
        old_total_cover: u256,
        new_total_cover: u256,
        updated_by: ContractAddress,
        timestamp: u64
    }

    #[derive(Drop, starknet::Event)]
    struct ProtocolPremiumUpdated {
        protocol_name: felt252,
        old_total_premium: u256,
        new_total_premium: u256,
        updated_by: ContractAddress,
        timestamp: u64
    }

    #[constructor]
    fn constructor(ref self: ContractState, owner: ContractAddress) {
        self.owner.write(owner);
        self.is_initialized.write(true);
    }

    fn validate_protocol_name(
        ref self: ContractState,
        protocol_name: felt252
    ) -> bool {
        // Check if caller is owner
        let caller = get_caller_address();
        let owner = self.owner.read();
        assert(caller == owner, 'Unauthorized');

        // Validate name length
      
        let name_length = protocol_name.len();
        if name_length < MIN_PROTOCOL_NAME_LENGTH {
            self.emit(ProtocolValidationFailed { 
                protocol_name, 
                error: 'name_too_short' 
            });
            return false;
        }
        if name_length > MAX_PROTOCOL_NAME_LENGTH {
            self.emit(ProtocolValidationFailed { 
                protocol_name, 
                error: 'name_too_long' 
            });
            return false;
        }

        // Validate name format (must start with PROTOCOL_NAME_PREFIX)
        if protocol_name != PROTOCOL_NAME_PREFIX {
            // TODO: Implement proper string prefix checking when available
            self.emit(ProtocolValidationFailed { 
                protocol_name, 
                error: 'invalid_name_format' 
            });
            return false;
        }

        // Check if protocol name already exists
        let protocol = self.protocols.read(protocol_name);
        if protocol.name != 0 {
            self.emit(ProtocolValidationFailed { 
                protocol_name, 
                error: 'name_already_exists' 
            });
            return false;
        }

        true
    }

    fn validate_risk_score(ref self: ContractState, risk_score: u8) -> bool {
        // Check if caller is owner
        let caller = get_caller_address();
        let owner = self.owner.read();
        assert(caller == owner, 'Unauthorized');

        // Validate risk score range
        if risk_score < MIN_RISK_SCORE || risk_score > MAX_RISK_SCORE {
            return false;
        }

        true
    }

    fn update_protocol_risk_score(
        ref self: ContractState,
        protocol_name: felt252,
        new_risk_score: u8
    ) -> bool {
        // Validate risk score
        assert(validate_risk_score(ref self, new_risk_score), 'Invalid risk score');

        // Check if protocol exists
        let protocol = self.protocols.read(protocol_name);
        assert(protocol.name != 0, 'Protocol not found');

        // Store old risk score for event
        let old_risk_score = protocol.risk_score;

        // Update protocol with new risk score
        let updated_protocol = Protocol {
            name: protocol.name,
            risk_score: new_risk_score,
            total_cover: protocol.total_cover,
            total_premium: protocol.total_premium,
            is_active: protocol.is_active,
            created_at: protocol.created_at
        };

        // Write updated protocol
        self.protocols.write(protocol_name, updated_protocol);

        // Emit event
        self.emit(ProtocolRiskUpdated {
            protocol_name,
            old_risk_score,
            new_risk_score,
            updated_by: get_caller_address(),
            timestamp: starknet::get_block_timestamp(),
            reason: 'Risk score updated'
        });

        true
    }

    fn emit_protocol_created(
        ref self: ContractState,
        protocol_name: felt252,
        risk_score: u8
    ) {
        self.emit(ProtocolCreated {
            protocol_name,
            risk_score,
            created_by: get_caller_address(),
            timestamp: starknet::get_block_timestamp()
        });
    }

    fn emit_protocol_updated(
        ref self: ContractState,
        protocol_name: felt252,
        old_risk_score: u8,
        new_risk_score: u8
    ) {
        self.emit(ProtocolUpdated {
            protocol_name,
            old_risk_score,
            new_risk_score,
            updated_by: get_caller_address(),
            timestamp: starknet::get_block_timestamp()
        });
    }

    fn emit_protocol_deactivated(
        ref self: ContractState,
        protocol_name: felt252,
        reason: felt252
    ) {
        self.emit(ProtocolDeactivated {
            protocol_name,
            deactivated_by: get_caller_address(),
            timestamp: starknet::get_block_timestamp(),
            reason
        });
    }

    fn emit_protocol_reactivated(
        ref self: ContractState,
        protocol_name: felt252
    ) {
        self.emit(ProtocolReactivated {
            protocol_name,
            reactivated_by: get_caller_address(),
            timestamp: starknet::get_block_timestamp()
        });
    }

    fn emit_protocol_removed(
        ref self: ContractState,
        protocol_name: felt252,
        reason: felt252
    ) {
        self.emit(ProtocolRemoved {
            protocol_name,
            removed_by: get_caller_address(),
            timestamp: starknet::get_block_timestamp(),
            reason
        });
    }

    fn emit_protocol_risk_updated(
        ref self: ContractState,
        protocol_name: felt252,
        old_risk_score: u8,
        new_risk_score: u8,
        reason: felt252
    ) {
        self.emit(ProtocolRiskUpdated {
            protocol_name,
            old_risk_score,
            new_risk_score,
            updated_by: get_caller_address(),
            timestamp: starknet::get_block_timestamp(),
            reason
        });
    }

    fn emit_protocol_cover_updated(
        ref self: ContractState,
        protocol_name: felt252,
        old_total_cover: u256,
        new_total_cover: u256
    ) {
        self.emit(ProtocolCoverUpdated {
            protocol_name,
            old_total_cover,
            new_total_cover,
            updated_by: get_caller_address(),
            timestamp: starknet::get_block_timestamp()
        });
    }

    fn emit_protocol_premium_updated(
        ref self: ContractState,
        protocol_name: felt252,
        old_total_premium: u256,
        new_total_premium: u256
    ) {
        self.emit(ProtocolPremiumUpdated {
            protocol_name,
            old_total_premium,
            new_total_premium,
            updated_by: get_caller_address(),
            timestamp: starknet::get_block_timestamp()
        });
    }
}

    // TODO: Implement core functions
    // - create_pool
    // - add_protocol
    // - buy_cover
    // - claim_cover
    // - get_protocols
    // - get_protocol_details
    // - get_user_cover
    // - get_total_liquidity