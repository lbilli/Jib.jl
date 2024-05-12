@testset "Wrapper" begin
    @testset "Constructors" begin
        w = InteractiveBrokers.Wrapper(tickSize=(x) -> x)
        @test isnothing(getfield(w, :clientObject))
    end
    @testset "Interfaces" begin
        @testset "Without clientObject" begin
            w = InteractiveBrokers.Wrapper(tickSize=(x) -> x)
            @test w.tickSize(14) == 14
            @test InteractiveBrokers.forward(w, :tickSize, 14) == 14
        end
        @testset "With clientObject" begin
            struct IBTestClientObject
            end
            tstObj = IBTestClientObject()
            w = InteractiveBrokers.Wrapper(tstObj, tickSize=(obj, x) -> (obj, x + 1))
            @test w.tickSize(tstObj, 14) == (tstObj, 15)
            @test InteractiveBrokers.forward(w, :tickSize, 14) == (tstObj, 15)
        end
    end
end