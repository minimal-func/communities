# README

## Ethereum wallet authentication

Authentication is invite-only:

1. Bootstrap the first member with `INITIAL_MEMBER_WALLET=0x... bin/rails db:seed`.
2. Community admins add members via `POST /communities/:community_id/members`; non-existent wallets are auto-invited.
3. A member or invited wallet requests a challenge with `POST /session/nonce` and `wallet_address`.
4. The wallet signs the returned `message` with `personal_sign`.
5. The client completes login with `POST /session`, sending `wallet_address`, `nonce`, and `signature`.

Invited wallets become members only after successfully signing their own challenge.

This README would normally document whatever steps are necessary to get the
application up and running.

Things you may want to cover:

* Ruby version

* System dependencies

* Configuration

* Database creation

* Database initialization

* How to run the test suite

* Services (job queues, cache servers, search engines, etc.)

* Deployment instructions

* ...
