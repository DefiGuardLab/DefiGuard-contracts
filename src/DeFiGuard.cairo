#[starknet::contract]
pub mod DeFiGuard {
    use starknet::storage::StorageMapWriteAccess;
use starknet::storage::StoragePointerReadAccess;
    use starknet::storage::StorageMapReadAccess;
    use starknet::storage::StoragePointerWriteAccess;
    use starknet::storage::Map;
    use starknet::ContractAddress;
    use starknet::get_caller_address;

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
        ProtocolAdded: ProtocolAdded,
        CoverPurchased: CoverPurchased,
        CoverClaimed: CoverClaimed,
        LiquidityAdded: LiquidityAdded,
        ProtocolValidationFailed: ProtocolValidationFailed,
        RiskScoreUpdated: RiskScoreUpdated
    }

    #[derive(Drop, starknet::Event)]
    struct ProtocolAdded {
        protocol_name: felt252,
        risk_score: u8
    }

    #[derive(Drop, starknet::Event)]
    struct CoverPurchased {
        user: ContractAddress,
        protocol_name: felt252,
        cover_amount: u256,
        premium_paid: u256
    }

    #[derive(Drop, starknet::Event)]
    struct CoverClaimed {
        user: ContractAddress,
        protocol_name: felt252,
        claim_amount: u256
    }

    #[derive(Drop, starknet::Event)]
    struct LiquidityAdded {
        provider: ContractAddress,
        amount: u256
    }

    #[derive(Drop, starknet::Event)]
    struct ProtocolValidationFailed {
        protocol_name: felt252,
        error: felt252
    }

    #[derive(Drop, starknet::Event)]
    struct RiskScoreUpdated {
        protocol_name: felt252,
        old_risk_score: u8,
        new_risk_score: u8,
        updated_by: ContractAddress
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