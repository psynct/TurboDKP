local TDKP_Tests = {}
_G["TDKP_Tests"] = TDKP_Tests

function TDKP_Tests:RunTests()
    if WoWUnit == nil then
        return
    end

    local AreEqual, Exists, Replace = WoWUnit.AreEqual, WoWUnit.Exists, WoWUnit.Replace
    local Tests = WoWUnit:NewGroup("TurboDKP")

    function Tests:ApplyBiddingCaps1()
        AreEqual(pack(100, 50), pack(TDKP_WinnerCalculator:ApplyBiddingCaps({bidAmount=100}, {bidAmount=50}, -1, -1, -1, -1)))
    end
    function Tests:ApplyBiddingCaps2()
        AreEqual(pack(100, 150), pack(TDKP_WinnerCalculator:ApplyBiddingCaps({bidAmount=100}, {bidAmount=150}, 50, -1, -1, 50)))
    end
    function Tests:ApplyBiddingCaps3()
        AreEqual(pack(49, 150), pack(TDKP_WinnerCalculator:ApplyBiddingCaps({bidAmount=100}, {bidAmount=150}, 49, -1, -1, 50)))
    end
    function Tests:ApplyBiddingCaps4()
        AreEqual(pack(50, 69), pack(TDKP_WinnerCalculator:ApplyBiddingCaps({bidAmount=100}, {bidAmount=69}, 50, 150, -1, -1)))
    end
    function Tests:ApplyBiddingCaps5()
        AreEqual(pack(50, 51), pack(TDKP_WinnerCalculator:ApplyBiddingCaps({bidAmount=55}, {bidAmount=51}, -1, -1, 50, -1)))
    end
    function Tests:ApplyBiddingCaps6()
        AreEqual(pack(100, 150), pack(TDKP_WinnerCalculator:ApplyBiddingCaps({bidAmount=100}, {bidAmount=150}, -1, -1, 50, 50)))
    end
    function Tests:ApplyBiddingCaps7()
        AreEqual(pack(102, 101), pack(TDKP_WinnerCalculator:ApplyBiddingCaps({bidAmount=102}, {bidAmount=101}, 150, 50, 50, -1)))
    end
    function Tests:ApplyBiddingCaps8()
        AreEqual(pack(100, 48), pack(TDKP_WinnerCalculator:ApplyBiddingCaps({bidAmount=100}, {bidAmount=101}, 103, 48, 49, 102)))
    end

    WoWUnit:RunTests("PLAYER_LOGIN")
end
