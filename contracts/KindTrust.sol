pragma solidity ^0.4.18;

contract Kindtrust {
  struct Organization {
    // An image and description per item will be written to IPFS; resulting hashes stored here
    address organization;
    string name;
    string ipfsImgHash;
    string ipfsDescHash;
    uint totalReceived;
    uint totalSpent;

    // People can rate projects for efficiency of spending (0-100%)
    // This is the sum of these ratings (unweighted to keep big charities accountable on small projects)
    uint efficiencyRatingsSum;

    // Number across all projects (more = more reliable). Average rating is efficiencyRatingsSum / numEfficiencyRatings.
    uint numEfficiencyRatings;

    // List of all the organization's project IDs; total paid to supplier by address; list of all suppliers worked with
    uint[] projects;
    mapping (address => uint) supplierTotals;
    address[] suppliers;
  }

  // Mapping of address to organization and list of all organization addresses
  mapping (address => Organization) organizationByAddress;
  address[] organizations;

  struct Project {
    uint projectId;
    address organization;
    string name;
    string category;
    string ipfsImgHash;
    string ipfsDescHash;
    uint goal;
    uint totalReceived;
    uint totalSpent;

    // People should be able to update their rating. This keeps track of who rated this project and the rating they gave.
    mapping (address => bool) ratedEfficiency;
    mapping (address => uint) efficiencyRating;

    // Mapping of supplier address to list of purchase IDs with that supplier
    mapping (address => uint[]) supplierPurchases;
    mapping (address => uint) supplierTotals;
    address[] suppliers;
  }

  // Mapping of projectId to project and list of all projectIds
  mapping (uint => Project) projectById;
  uint[] projects;

  struct Supplier {
    address supplier;
    string name;
    string ipfsImgHash;
    string ipfsDescHash;
    uint totalReceived;

    // Mapping of organization address to total received; list of all organizations worked with
    mapping (address => uint) organizationTotals;
    address[] organizations;

    // Mapping of project ID to list of purchase IDs; mapping of project ID to total received; projects worked with
    mapping (uint => uint[]) projectPurchases;
    mapping (uint => uint) projectTotals;
    uint[] projects;
  }

  mapping (address => Supplier) supplierByAddress;
  address[] suppliers;

  struct Purchase {
    // Time of purchase is in seconds since epoch
    uint purchaseId;
    uint projectId;
    address supplier;
    uint amount;
    string ipfsDescHash;
    uint timestamp;
  }

  // Mapping of purchase ID to Purchase
  mapping (uint => Purchase) purchaseById;

  // Counters for unique indexes
  uint public projectIndex;
  uint public purchaseIndex;

  // Information for donors: mapping from projectId to amount, list of projectIds donated to, total donated
  mapping (address => mapping (uint => uint)) donatedPerProject;
  mapping (address => uint[]) projectsDonatedTo;
  mapping (address => uint) totalDonated;

  // Platform usage statistics
  uint numDonors;
  uint amountDonated;
  uint amountSpent;

  // Events for a server to listen to, server can store in DB for easier querying
  event NewOrganization(address _organization, string _name, string _ipfsImgHash, string _ipfsDescHash);
  event NewProject(uint _projectIndex, address _organization, string _name, string _category, string _ipfsImgHash,
      string _ipfsDeschash, uint _goal);
  event NewSupplier(address _supplier, string _name, string _ipfsImgHash, string _ipfsDescHash);
  event NewDonation(address _donor, uint _projectId, uint _amount);
  event NewPurchase(uint _purchaseId, uint _projectId, address _supplier, uint _amount, string _ipfsDescHash,
      uint _timestamp);
  event Rate(address _rater, uint _projectId, uint _rating);

  // Constructor
  function KindTrust() public {
    projectIndex = 0;
    purchaseIndex = 0;
  }

  // Index-of helper functions
  function indexOfUint(uint[] arr, uint element) pure public returns (uint) {
    for (uint i = 0; i < arr.length; i++) {
      if (arr[i] == element) {
        return i;
      }
    }
    return uint(-1);
  }

  function indexOfAddress(address[] arr, address element) pure public returns (uint) {
    for (uint i = 0; i < arr.length; i++) {
      if (arr[i] == element) {
        return i;
      }
    }
    return uint(-1);
  }

  // Add organizations, projects, and suppliers
  function addOrganization(string _name, string _ipfsImgHash, string _ipfsDescHash) public {
    // Cannot override existing organizations
    require(organizationByAddress[msg.sender].organization == 0);

    Organization memory organization = Organization(msg.sender, _name, _ipfsImgHash, _ipfsDescHash, 0, 0, 0, 0,
        new uint[](0), new address[](0));
    organizationByAddress[msg.sender] = organization;
    organizations.push(msg.sender);

    NewOrganization(msg.sender, _name, _ipfsImgHash, _ipfsDescHash);
  }

  function addProject(string _name, string _category, string _ipfsImgHash, string _ipfsDescHash, uint _goal) public {
    // Sender must be a registered organization
    require(organizationByAddress[msg.sender].organization != 0);

    Project memory project = Project(projectIndex, msg.sender, _name, _category, _ipfsImgHash, _ipfsDescHash,
        _goal, 0, 0, new address[](0));
    projectById[projectIndex] = project;
    projects.push(projectIndex);

    organizationByAddress[msg.sender].projects.push(projectIndex);
    NewProject(projectIndex, msg.sender, _name, _category, _ipfsImgHash, _ipfsDescHash, _goal);
    projectIndex += 1;
  }

  function addSupplier(string _name, string _ipfsImgHash, string _ipfsDescHash) public {
    // Cannot override existing suppliers
    require(supplierByAddress[msg.sender].supplier == 0);

    Supplier memory supplier = Supplier(msg.sender, _name, _ipfsImgHash, _ipfsDescHash, 0, new address[](0),
        new uint[](0));
    supplierByAddress[msg.sender] = supplier;
    suppliers.push(msg.sender);

    NewSupplier(msg.sender, _name, _ipfsImgHash, _ipfsDescHash);
  }

  // Get organizations, projects, and suppliers
  function getOrganization(address _organization) view public returns (string, string, string, uint, uint, uint, uint,
      uint[], address[]) {
    Organization memory o = organizationByAddress[_organization];
    return (o.name, o.ipfsImgHash, o.ipfsDescHash, o.totalReceived, o.totalSpent, o.efficiencyRatingsSum,
        o.numEfficiencyRatings, o.projects, o.suppliers);
  }

  function getProject(uint _projectId) view public returns (address, string, string, string, string, uint, uint, uint,
      address[]) {
    Project memory p = projectById[_projectId];
    return (p.organization, p.name, p.category, p.ipfsImgHash, p.ipfsDescHash, p.goal, p.totalReceived, p.totalSpent,
        p.suppliers);
  }

  function getSupplier(address _supplier) view public returns (string, string, string, uint, address[], uint[]) {
    Supplier memory s = supplierByAddress[_supplier];
    return (s.name, s.ipfsImgHash, s.ipfsDescHash, s.totalReceived, s.organizations, s.projects);
  }

  function getPurchase(uint _purchaseId) view public returns (uint, uint, address, uint, string, uint) {
    Purchase memory p = purchaseById[_purchaseId];
    return (p.purchaseId, p.projectId, p.supplier, p.amount, p.ipfsDescHash, p.timestamp);
  }

  function getOrganizations() view public returns (address[]) {
    return organizations;
  }

  function getProjects() view public returns (uint[]) {
    return projects;
  }

  function getSuppliers() view public returns (address[]) {
    return suppliers;
  }

  function donate(uint _projectId) payable public returns (bool) {
    // Users can call this payable function to donate to a project; the money will be stored here
    require(msg.value > 0);

    // Update organization state
    organizationByAddress[msg.sender].totalReceived += msg.value;

    // Project state
    projectById[_projectId].totalReceived += msg.value;

    // Donor state
    donatedPerProject[msg.sender][_projectId] += msg.value;
    if (indexOfUint(projectsDonatedTo[msg.sender], _projectId) == uint(-1)) {
      projectsDonatedTo[msg.sender].push(_projectId);
    }
    totalDonated[msg.sender] += msg.value;

    // Platform statistics
    if (totalDonated[msg.sender] == msg.value) {
      // Increment number of donors if donor's total donated equals this (first) donation
      numDonors += 1;
    }
    amountDonated += msg.value;

    // Event for new donation
    NewDonation(msg.sender, _projectId, msg.value);
    return true;
  }

  function spend(uint _projectId, address _supplier, uint _amount, string _ipfsDescHash) public {
    // Only the owner of a project can spend from the project's donations
    Project storage project = projectById[_projectId];
    require(_amount > 0);
    require(project.organization == msg.sender);
    require(project.totalReceived - project.totalSpent >= _amount);

    // Supplier must be registered
    require(supplierByAddress[_supplier].supplier != 0);

    // Transfer money to the supplier
    _supplier.transfer(_amount);

    // Update organization state
    Organization storage organization = organizationByAddress[project.organization];
    organization.totalSpent += _amount;
    organization.supplierTotals[_supplier] += _amount;
    if (indexOfAddress(organization.suppliers, _supplier) == uint(-1)) {
      organization.suppliers.push(_supplier);
    }

    // Create purchase instance, with time in seconds since epoch
    Purchase memory purchase = Purchase(purchaseIndex, _projectId, _supplier, _amount, _ipfsDescHash, now);
    purchaseById[purchaseIndex] = purchase;

    // Project state
    project.totalSpent += _amount;
    project.supplierPurchases[_supplier].push(purchaseIndex);
    project.supplierTotals[_supplier] == _amount;
    if (indexOfAddress(project.suppliers, _supplier) == uint(-1)) {
      project.suppliers.push(_supplier);
    }

    // Supplier state (interacts with both organization and project)
    Supplier storage supplier = supplierByAddress[_supplier];
    supplier.totalReceived += _amount;
    supplier.organizationTotals[project.organization] += _amount;
    if (indexOfAddress(supplier.organizations, project.organization) == uint(-1)) {
      supplier.organizations.push(project.organization);
    }
    supplier.projectPurchases[_projectId].push(purchaseIndex);
    supplier.projectTotals[_projectId] += _amount;
    if (indexOfUint(supplier.projects, _projectId) == uint(-1)) {
      supplier.projects.push(_projectId);
    }

    // Platform usage statistics
    amountSpent += _amount;

    // Event for new purchase
    NewPurchase(purchaseIndex, _projectId, _supplier, _amount, _ipfsDescHash, now);
    purchaseIndex += 1;
  }

  function rate(uint _projectId, uint _rating) public {
    // The rating must be a valid percentage [0-100]
    Project storage project = projectById[_projectId];
    require(_rating <= 100);

    // To prevent trolling, users can only rate projects they have donated to
    require(donatedPerProject[msg.sender][_projectId] > 0);

    // Also, organization behind the project cannot rate it
    require(project.organization != msg.sender);

    Organization storage organization = organizationByAddress[project.organization];

    // Check if user is rating this project for the first time
    if (project.ratedEfficiency[msg.sender] != true) {
      // Update organization state
      organization.efficiencyRatingsSum += _rating;
      organization.numEfficiencyRatings += 1;

      // Update project state
      project.ratedEfficiency[msg.sender] = true;
      project.efficiencyRating[msg.sender] = _rating;
    } else {
      // User is updating a previous rating
      organization.efficiencyRatingsSum += _rating;
      organization.efficiencyRatingsSum -= project.efficiencyRating[msg.sender];
      project.efficiencyRating[msg.sender] = _rating;
    }

    // Event
    Rate(msg.sender, _projectId, _rating);
  }
}
