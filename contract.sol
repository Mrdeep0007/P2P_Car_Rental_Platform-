// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract P2PCarRental {
    struct Car {
        uint256 id;
        string make;
        string model;
        uint256 year;
        uint256 dailyRate;
        address payable owner;
        bool available;
    }

    struct Rental {
        uint256 carId;
        address renter;
        uint256 startDate;
        uint256 endDate;
        uint256 totalCost;
    }

    uint256 private carCounter;
    mapping(uint256 => Car) public cars;
    mapping(uint256 => Rental[]) public rentals;

    event CarListed(uint256 carId, address owner);
    event CarRented(uint256 carId, address renter, uint256 startDate, uint256 endDate);
    event RentalCompleted(uint256 carId, address renter);

    modifier onlyCarOwner(uint256 _carId) {
        require(cars[_carId].owner == msg.sender, "Only the car owner can perform this action");
        _;
    }

    modifier carAvailable(uint256 _carId) {
        require(cars[_carId].available, "Car is not available for rent");
        _;
    }

    function listCar(
        string memory _make,
        string memory _model,
        uint256 _year,
        uint256 _dailyRate
    ) public {
        carCounter++;
        cars[carCounter] = Car({
            id: carCounter,
            make: _make,
            model: _model,
            year: _year,
            dailyRate: _dailyRate,
            owner: payable(msg.sender),
            available: true
        });
        emit CarListed(carCounter, msg.sender);
    }

    function rentCar(uint256 _carId, uint256 _startDate, uint256 _endDate)
        public
        payable
        carAvailable(_carId)
    {
        require(_startDate < _endDate, "Invalid rental period");

        uint256 rentalDays = (_endDate - _startDate) / 1 days;
        uint256 totalCost = rentalDays * cars[_carId].dailyRate;

        require(msg.value >= totalCost, "Insufficient payment");

        rentals[_carId].push(Rental({
            carId: _carId,
            renter: msg.sender,
            startDate: _startDate,
            endDate: _endDate,
            totalCost: totalCost
        }));

        cars[_carId].available = false;
        cars[_carId].owner.transfer(totalCost);

        emit CarRented(_carId, msg.sender, _startDate, _endDate);
    }

    function completeRental(uint256 _carId) public onlyCarOwner(_carId) {
        require(!cars[_carId].available, "Rental is already completed");

        cars[_carId].available = true;

        emit RentalCompleted(_carId, rentals[_carId][rentals[_carId].length - 1].renter);
    }

    function getCarDetails(uint256 _carId)
        public
        view
        returns (
            string memory make,
            string memory model,
            uint256 year,
            uint256 dailyRate,
            address owner,
            bool available
        )
    {
        Car memory car = cars[_carId];
        return (car.make, car.model, car.year, car.dailyRate, car.owner, car.available);
    }

    function getRentalHistory(uint256 _carId) public view returns (Rental[] memory) {
        return rentals[_carId];
    }
}
