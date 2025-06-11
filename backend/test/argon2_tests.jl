import Argon2

test_password = "MySuperSecretPassword123!"

@testset "Hash and verify correct password"
    hashed_pwd = Argon2.hash_password(test_password)
    @test Argon2.verify_password(test_password, hashed_pwd)
end

@testset "Hash and verify incorrect password"
    hashed_pwd = Argon2.hash_password(test_password)
    incorrect_password = "WrongPassword"
    @test Argon2.verify_password(incorrect_password, hashed_pwd) == false
end