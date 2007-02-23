function clearInitialText(input) {
    if (input.alreadyCleared) return;    
    input.alreadyCleared = true;
    input.value = "";
}

function checkEmailOnSubmit(input) {
    if (!input.alreadyCleared) {
        clearInitialText(input);
    }
    if (input.value == '') { 
        alert('Please enter an email address.'); 
        return false;
    }
    return true;
}
