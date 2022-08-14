%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.uint256 import Uint256
# from starkware.cairo.common.serialize import serialize_word
from starkware.cairo.common.math import (
    assert_not_zero,
    assert_le,
    assert_lt
)

# from cairo_string.String import (
#     String_get, String_set, String_delete, String_append, String_path_join, String_felt_to_string,
#     String_extract_last_char)

from starkware.starknet.common.syscalls import (
    get_block_timestamp,
    get_caller_address,
    get_contract_address,
    )

# from token import call_approve

# from openzeppelin.token.erc20.interfaces.IERC20 import IERC20
# from openzeppelin.utils.constants import False, True

#todo struct Person with attributes of reputation or experience

struct Task:
    member task_creator : felt
    member task_hash : felt
    member field: felt
    member reward : Uint256
    member start_at: felt
    member end_at: felt
    member is_approved: felt # not used yet
end

struct Work:
    member task_id: felt
    member worker: felt
    member work_hash: felt
end

#
# storage
#
@storage_var
func owner() -> (owner_address: felt):
end

@storage_var
func is_voter_registered(task_id: felt, voter: felt) -> (res: felt):
end

@storage_var
func has_voted(work_id: felt, voter: felt) -> (res: felt):
end

@storage_var
func num_voters(task_id: felt) -> (res: felt):
end

@storage_var
func tasks(task_id: felt) -> (res: Task):
end

@storage_var
func num_tasks() -> (res: felt):
end

# work_id is continuous integers regardless of relevant task_id
@storage_var
func works(work_id: felt) -> (res: Work): 
end

@storage_var
func num_works() -> (res: felt):
end

@storage_var
func vote_result(work_id: felt, answer: felt) -> (res: felt):
end

#
# viewer
#
@view
func get_owner{syscall_ptr : felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
    }() -> (res: felt):
    let (res) = owner.read()
    return (res)
end

@view
func get_task{syscall_ptr : felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
    }(task_id: felt) -> (res: Task):
    let (res) = tasks.read(task_id)
    return (res)
end

@view
func get_work{syscall_ptr : felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
    }(work_id: felt) -> (res: Work):
    let (res) = works.read(work_id)
    return (res)
end

@view
func get_is_voter_registered{syscall_ptr : felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
    }(task_id: felt, voter: felt) -> (res: felt):
    let (res) = is_voter_registered.read(task_id, voter)
    return (res)
end

@view
func get_has_voted{syscall_ptr : felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
    }(work_id: felt, voter: felt) -> (res: felt):
    let (res) = has_voted.read(work_id, voter)
    return (res)
end

@view
func get_num_voters{syscall_ptr : felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
    }(task_id: felt) -> (res: felt):
    let (res) = num_voters.read(task_id)
    return (res)
end

@view
func get_num_tasks{syscall_ptr : felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
    }() -> (res: felt):
    let (res) = num_tasks.read()
    return (res)
end

@view
func get_num_works{syscall_ptr : felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
    }() -> (res: felt):
    let (res) = num_works.read()
    return (res)
end


@view
func get_vote_result{syscall_ptr : felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
    }(work_id: felt, answer: felt) -> (res: felt):
    let (res) = vote_result.read(work_id, answer)
    return (res)
end

#
# constructor
#
@constructor
func constructor{syscall_ptr : felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
    }(owner_address: felt):
    let (caller_address) = get_caller_address()
    owner.write(owner_address)
    # check_is_owner()
    return ()
end

#
# External Functions
#
@external
func launch_task{syscall_ptr : felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
    }(task_hash: felt, 
    field: felt, 
    reward: Uint256, 
    end_at: felt, 
    first_voter: felt, #todo Now the task_creator can specify who are the voters for the task. In the future, logic of fair selection should be implemented.
    second_voter: felt,
    third_voter: felt,
    new_num_voters: felt
    ):
    let (current_task_id) = num_tasks.read()
    let (task_creator) = get_caller_address()
    let (start_at) = get_block_timestamp() #todo start immdediately when task is created. probably to be reconsidered
    let (current_task_id) = num_tasks.read()

    # with_attr error_message("task shold end later than start time"):
    #     assert_lt(start_at, end_at)
    # end
    tempvar new_task = Task(
        task_creator=task_creator,
        task_hash=task_hash,
        field=field,
        reward=reward,
        start_at=start_at,
        end_at=end_at,
        is_approved=0,
    )
    num_voters.write(current_task_id, new_num_voters)
    tasks.write(current_task_id, new_task)
    
    is_voter_registered.write(current_task_id, first_voter, 1)
    is_voter_registered.write(current_task_id, second_voter, 1)
    is_voter_registered.write(current_task_id, third_voter, 1)

    let next_task_id = current_task_id + 1
    num_tasks.write(next_task_id)
    
    # let (this_contract) = get_contract_address() #todo get_contract_address?
    
    # let (balance) = call_balanceOf(task_creator)
    # # assert_le(reward*(10**18), balance)   #todo How can compare between Uint256 and felt?
    # let (result) = call_approve(this_contract, reward)
    # assert result = 1
    return()
end


@external
func submit_work{
    syscall_ptr : felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
    }(task_id: felt, work_hash: felt):
    let (worker) = get_caller_address()
    let (current_work_id) = num_works.read()

    # with_attr error_message("work shold be submitted earlier than end time"):
    #     let (current_time) = get_block_timestamp()
    #     assert_le(current_time, end_at)
    # end
    
    tempvar new_work = Work(
    task_id=task_id,
    worker=worker,
    work_hash=work_hash
    )

    works.write(current_work_id, new_work)
    let next_work_id = current_work_id + 1
    num_works.write(next_work_id)
    return()
end

# task id is not necessary but now included for making coding easier
@external
func vote{
    syscall_ptr : felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
    }(task_id: felt, work_id: felt, answer: felt): 
    # let (work) = works.read(work_id)
    # let (relevant_task_id) = work.task_id
    let (caller) = get_caller_address()

    with_attr error_message("You are not allowed to vote"):
        let (is_registered) = is_voter_registered.read(caller, task_id)
        assert is_registered = 1
    end

    with_attr error_message("You have already voted"):
        # assert has_voted.read(caller, work_id) = 0
    end

    has_voted.write(work_id, caller, 1)
    let (current_vote_result) = vote_result.read(work_id, answer)
    let new_vote_result = current_vote_result + 1
    vote_result.write(work_id, answer, new_vote_result)
    return()
end

@external
func withdrawReward{
    syscall_ptr : felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
    }(work_id: felt):
    let (work) = get_work(work_id)
    let task_id = work.task_id
    let (task) = get_task(task_id)
    let reward = task.reward

    let (caller) = get_caller_address()
    let (work) = get_work(work_id)
    let worker = work.worker

    let (positive_answer) = get_vote_result(work_id, 1)
    assert_le(2, positive_answer)
    let (this_contract) = get_contract_address()
    let ERC20_ADDRESS: felt = 3446953496383086514921099742104360957960669234955524576298876500315583199321
    let (result) = call_transferFrom(ERC20_ADDRESS, this_contract, caller, reward)
    assert result = 1
    return()
end

@contract_interface
namespace IErc20Contract:
    func balanceOf(account: felt) -> (amount: Uint256):
    end

    # func tranfer(recipient: felt, amount: Uint256) -> (success: felt):
    # end

    func approve(spender: felt, amount: Uint256) -> (success: felt):
    end
    
    func transferFrom(sender: felt, recipient: felt, amount: Uint256) -> (success: felt):
    end
end

@external
func call_approve{
    syscall_ptr : felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
    }(contract_address: felt, spender: felt, amount: Uint256) -> (success: felt):
    let (res) =IErc20Contract.approve(contract_address=contract_address, spender=spender, amount=amount)
    return(res)
end

@view
func call_balanceOf{
    syscall_ptr : felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
    }(contract_address: felt, account: felt) -> (amount: Uint256):
    # let ERC20_ADDRESS: felt = 3446953496383086514921099742104360957960669234955524576298876500315583199321
    let (res) =IErc20Contract.balanceOf(contract_address, account)
    return(res)
end

# @external
# func call_transfer{
#     syscall_ptr : felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
#     }(contract_address: felt, recipient: felt, amount: Uint256) -> (success: felt):
#     let (res) =IErc20Contract.transfer(contract_address, recipient, amount)
#     return(res)
# end

@external
func call_transferFrom{
    syscall_ptr : felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
    }(contract_address: felt, sender: felt, recipient: felt, amount: Uint256) -> (success: felt):
    let (res) = IErc20Contract.transferFrom(contract_address, sender, recipient, amount)
    return(res)
end
