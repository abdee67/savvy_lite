package com.stock.jsf;

import com.stock.entity.*;
import com.stock.jsf.util.JsfUtil;
import com.stock.jsf.util.JsfUtil.PersistAction;
import com.stock.security.LoginView;
import com.stock.session.ItemTransactionsFacade;

import java.io.Serializable;
import java.time.Instant;
import java.time.LocalDate;
import java.time.LocalTime;
import java.time.ZoneId;
import java.util.*;
import java.util.logging.Level;
import java.util.logging.Logger;

import jakarta.ejb.EJB;
import jakarta.ejb.EJBException;
import jakarta.inject.Inject;
import jakarta.inject.Named;
import jakarta.enterprise.context.SessionScoped;
import jakarta.faces.component.UIComponent;

import java.util.stream.Collectors;

import jakarta.faces.context.FacesContext;
import jakarta.faces.convert.Converter;
import jakarta.faces.convert.FacesConverter;
import jakarta.persistence.EntityManager;
import jakarta.persistence.PersistenceContext;
import jakarta.persistence.TypedQuery;

@Named("itemTransactionsController")
@SessionScoped
public class ItemTransactionsController implements Serializable {

    @EJB
    private com.stock.session.ItemTransactionsFacade ejbFacade;
    @EJB
    private com.stock.session.AbstractFacadeQuery ejbFacade1;
    private List<ItemTransactions> items = null;
    private List<ItemTransactions> multiselectionItems = null;
    private List<ItemTransactions> createItems = null;
    private List<ItemTransactions> editItems = null;
    private List<ItemTransactions> filteredValues = null;
    private ItemTransactions selected;
    private ItemTransactions selected1;
    private ItemTransactions selected2 = new ItemTransactions();
    private String dataName = "ItemTransactions";
    protected int first;
    @Inject
    private LoginView loginView;
    private boolean isDuplicate = false;
    @PersistenceContext(unitName = "com.stock_library_war_1.0-SNAPSHOTPU")
    private EntityManager em;
    @Named("itemsInBranchController")
    @Inject
    private ItemsInBranchController itemsInBranchController;
    @Named("systemConstantController")
    @Inject
    private SystemConstantController systemConstantController;
    @Named("udcDetailsController")
    @Inject
    private UdcDetailsController udcDetailsController;
    @Named("nextNumberController")
    @Inject
    private NextNumberController nextNumberController;
    @Named("itemLocationsController")
    @Inject
    private ItemLocationsController itemLocationsController;
    @Named("lotMasterController")
    @Inject
    private LotMasterController lotMasterController;
    @Named("itemUomConversionsController")
    @Inject
    private ItemUomConversionsController itemUomConversionsController;
    @Inject
    private SalesOrderHeaderController salesOrderHeaderController;
    @Inject
    private ItemsTableController itemsTableController;
    private double totalOpeening = 0.0;
    @Inject
    private ItemCostTableController itemCostTableController;

    public ItemTransactionsController() {
    }

    public int getFirst() {
        return first;
    }

    public void setFirst(int first) {
        this.first = first;
    }

    public String getDataName() {
        return this.dataName;
    }

    public void setDataName(final String dataName) {
        this.dataName = dataName;
    }

    public ItemTransactions getSelected() {
        return selected;
    }

    public void setSelected(ItemTransactions selected) {
        this.selected = selected;
    }

    public ItemTransactions getSelected1() {
        return selected1;
    }

    public void setSelected1(ItemTransactions selected1) {
        this.selected1 = selected1;
    }

    public ItemTransactions getSelected2() {
        return selected2;
    }

    public void setSelected2(ItemTransactions selected2) {
        this.selected2 = selected2;
    }

    public void cancelUpdate() {
        selected1 = null;

        editItems = null;
    }

    public void discard() {
        selected = null;
        for (ItemTransactions item : getCreateItems()) {
            if (item.getId() != null) {
                getFacade().remove(item);
            }

        }
        createItems = null;
        items = null;
        if (!JsfUtil.isValidationFailed()) {
            // Invalidate list of items to trigger re-query.
            JsfUtil.addSuccessMessage("All records are removed");
        }
    }

    public void cancelCreate() {
        selected = null;
        createItems = null;
        items = null;
    }

    public void refreshList() {
        items = null;
    }

    protected void setEmbeddableKeys() {
    }

    protected void initializeEmbeddableKey() {
    }

    private ItemTransactionsFacade getFacade() {
        return ejbFacade;
    }

    public void stockCARDCreation(ItemsInBranch ib, ItemLocations loc, LotMaster lm, char transactionType, Integer trNo, String remark, double qty, PurchaseOrderReceiver por, SalesOrderDetails soD) {
        try {
            if (ib != null || loc != null || lm != null) {
                if (ib != null && !systemConstantController.getSelected1().getApplyLocationMgmBoolean() &&
                        !systemConstantController.getSelected1().getApplyLotMgmBoolean() && qty != 0.0) {
                    //Item Branch:
                    ItemTransactions item = new ItemTransactions();
                    item.setDateCreated(new Date());
                    UdcDetails udc = udcDetailsController.udcDetailByUDCHeaderAndCode("TT", String.valueOf(transactionType));
                    item.setTransactionType(udc);
                    Integer trNumber = por != null ? por.getPoDetail().getPoHeader().getOrderNumber() :
                            (soD != null ? soD.getSalesOrderHeaderId().getOrderNumber() : trNo);
                    if (trNumber == null) {
                        item.setTransactionNumber(nextNumberController.nextNumber("TN"));
                    } else {
                        item.setTransactionNumber(trNumber);
                    }
                    if (por != null) {
                        item.setSupplier(por.getPoDetail().getPoHeader().getSupplierId());
                        item.setOrderType(por.getPoDetail().getPoHeader().getOrderType());
                    }
                    if (soD != null) {
                        item.setCustomer(soD.getSalesOrderHeaderId().getCustomerTableId());
                        item.setOrderType(soD.getSalesOrderHeaderId().getOrderType());
                    }
                    String rerk = remark != null ? remark : (item.getTransactionType() != null ? item.getTransactionType().getDescription1() : "");
                    item.setRemark(rerk);
                    item.setQuantityTransaction(qty);
                    item.setItemBranch(ib);
                    item.setItemNumber(ib.getItemNumber());
                    item.setBranch(ib.getBranch());
                    item.setUnitOfMeasure(ib.getUnitOfMeasure());
                    item.setCompany(loginView.getAuthenticatedUser().getCompany());
                    double factor = itemUomConversionsController.fromOtherToAnother(item.getItemNumber(), item.getItemBranch().getUnitOfMeasure(), item.getUnitOfMeasure());
                    double qtyAvInstore = Math.abs(item.getItemBranch().getQuantityAvailable() == null ? 0.0 : item.getItemBranch().getQuantityAvailable()) + Math.abs(factor * qty);
                    item.setBeforeStoreQuantityAvailable(qtyAvInstore);
                    item.setUnitCost(itemCostTableController.itemCostTableByItem(item.getItemNumber()) == null? 0.0 : itemCostTableController.itemCostTableByItem(item.getItemNumber()).getAmountUnitCost());
                    double factorP = itemUomConversionsController.fromOtherToPrimary(item.getItemNumber(), item.getUnitOfMeasure());
                    double qTrn = Math.abs(factorP * qty);
                    item.setAmountCost(qTrn * item.getUnitCost());
                    double qBfrTrn = Math.abs(factorP * item.getBeforeStoreQuantityAvailable());
                    item.setBeforeAmountCost(qBfrTrn * item.getUnitCost());
                    ejbFacade.create(item);
                } else if (loc != null && systemConstantController.getSelected1().getApplyLocationMgmBoolean() &&
                        !systemConstantController.getSelected1().getApplyLotMgmBoolean() && qty != 0.0) {
                    //Item Branch:
                    ItemTransactions item = new ItemTransactions();
                    item.setDateCreated(new Date());
                    UdcDetails udc = udcDetailsController.udcDetailByUDCHeaderAndCode("TT", String.valueOf(transactionType));
                    item.setTransactionType(udc);
                    item.setQuantityTransaction(qty);
                    item.setItemLocation(loc);
                    List<ItemsInBranch> itemsInBranchList = itemsInBranchController.itemsAvailableSelectOneByItemAndBranch(loc.getItemNumber(), loc.getBranch());
                    item.setItemBranch(itemsInBranchList.isEmpty() ? null : itemsInBranchList.get(0));
                    Integer trNumber = por != null ? por.getPoDetail().getPoHeader().getOrderNumber() :
                            (soD != null ? soD.getSalesOrderHeaderId().getOrderNumber() : trNo);
                    if (trNumber == null) {
                        item.setTransactionNumber(nextNumberController.nextNumber("TN"));
                    } else {
                        item.setTransactionNumber(trNumber);
                    }
                    if (por != null) {
                        item.setSupplier(por.getPoDetail().getPoHeader().getSupplierId());
                        item.setOrderType(por.getPoDetail().getPoHeader().getOrderType());
                    }
                    if (soD != null) {
                        item.setCustomer(soD.getSalesOrderHeaderId().getCustomerTableId());
                        item.setOrderType(soD.getSalesOrderHeaderId().getOrderType());
                    }
                    String rerk = remark != null ? remark : (item.getTransactionType() != null ? item.getTransactionType().getDescription1() : "");
                    item.setRemark(rerk);
                    item.setBranch(loc.getBranch());
                    item.setItemNumber(loc.getItemNumber());
                    item.setUnitOfMeasure(itemsInBranchController.itemBranchUoM(loc.getItemNumber(), loc.getBranch()));
                    item.setCompany(loginView.getAuthenticatedUser().getCompany());
                    double factor = itemUomConversionsController.fromOtherToAnother(item.getItemNumber(), item.getItemBranch().getUnitOfMeasure(), item.getUnitOfMeasure());
                    double qtyAvInstore = Math.abs(item.getItemBranch().getQuantityAvailable() == null ? 0.0 : item.getItemBranch().getQuantityAvailable()) + Math.abs(factor * qty);
                    item.setBeforeStoreQuantityAvailable(qtyAvInstore);
                    item.setUnitCost(itemCostTableController.itemCostTableByItem(item.getItemNumber()) == null? 0.0 : itemCostTableController.itemCostTableByItem(item.getItemNumber()).getAmountUnitCost());
                    double factorP = itemUomConversionsController.fromOtherToPrimary(item.getItemNumber(), item.getUnitOfMeasure());
                    double qTrn = Math.abs(factorP * qty);
                    item.setAmountCost(qTrn * item.getUnitCost());
                    double qBfrTrn = Math.abs(factorP * item.getBeforeStoreQuantityAvailable());
                    item.setBeforeAmountCost(qBfrTrn * item.getUnitCost());
                    ejbFacade.create(item);
                } else if (lm != null && systemConstantController.getSelected1().getApplyLocationMgmBoolean() &&
                        systemConstantController.getSelected1().getApplyLotMgmBoolean() && qty != 0.0) {
                    //Item Branch:
                    ItemTransactions item = new ItemTransactions();
                    item.setDateCreated(new Date());
                    UdcDetails udc = udcDetailsController.udcDetailByUDCHeaderAndCode("TT", String.valueOf(transactionType));
                    item.setTransactionType(udc);
                    item.setQuantityTransaction(qty);
                    item.setItemLocation(lm.getLocation());
                    item.setLotNumber(lm);
                    item.setLotStatus(lm.getLotStatus());
                    List<ItemsInBranch> itemsInBranchList = itemsInBranchController.itemsAvailableSelectOneByItemAndBranch(lm.getItemNumber(), lm.getBranch());
                    item.setItemBranch(itemsInBranchList.isEmpty() ? null : itemsInBranchList.get(0));
                    Integer trNumber = por != null ? por.getPoDetail().getPoHeader().getOrderNumber() :
                            (soD != null ? soD.getSalesOrderHeaderId().getOrderNumber() : trNo);
                    if (trNumber == null) {
                        item.setTransactionNumber(nextNumberController.nextNumber("TN"));
                    } else {
                        item.setTransactionNumber(trNumber);
                    }
                    if (por != null) {
                        item.setSupplier(por.getPoDetail().getPoHeader().getSupplierId());
                        item.setOrderType(por.getPoDetail().getPoHeader().getOrderType());
                    }
                    if (soD != null) {
                        item.setCustomer(soD.getSalesOrderHeaderId().getCustomerTableId());
                        item.setOrderType(soD.getSalesOrderHeaderId().getOrderType());
                    }
                    String rerk = remark != null ? remark : (item.getTransactionType() != null ? item.getTransactionType().getDescription1() : "");
                    item.setBranch(lm.getBranch());
                    item.setItemNumber(lm.getItemNumber());
                    item.setUnitOfMeasure(itemsInBranchController.itemBranchUoM(lm.getItemNumber(), lm.getBranch()));
                    item.setRemark(rerk);
                    item.setCompany(loginView.getAuthenticatedUser().getCompany());
                    double qtyAvInstore = Math.abs(item.getItemBranch().getQuantityAvailable() == null ? 0.0 : item.getItemBranch().getQuantityAvailable());
                    item.setBeforeStoreQuantityAvailable(qtyAvInstore);
                    item.setUnitCost(itemCostTableController.itemCostTableByItem(item.getItemNumber()) == null? 0.0 : itemCostTableController.itemCostTableByItem(item.getItemNumber()).getAmountUnitCost());
                    double factorP = itemUomConversionsController.fromOtherToPrimary(item.getItemNumber(), item.getUnitOfMeasure());
                    double qTrn = Math.abs(factorP * qty);
                    item.setAmountCost(qTrn * item.getUnitCost());
                    double qBfrTrn = Math.abs(factorP * item.getBeforeStoreQuantityAvailable());
                    item.setBeforeAmountCost(qBfrTrn * item.getUnitCost());
                    ejbFacade.create(item);
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
            JsfUtil.addErrorMessage("Error Occurred, Please Contact Vendor!");
        }
    }

    public ItemTransactions prepareCreate() {
        createItems = new ArrayList<>();

        int tempid = 1;

        selected = new ItemTransactions();
        selected.setTempId(tempid);
        selected.setCompany(loginView.getAuthenticatedUser().getCompany());
        selected1 = new ItemTransactions();
        selected2 = new ItemTransactions();
        selected2.setTransactionNumber(nextNumberController.nextNumber("TN"));
        createItems.add(selected);
        initializeEmbeddableKey();
        return selected;
    }

    public ItemTransactions prepareCopy() {

        createItems = new ArrayList<>();
        selected = multiselectionItems.get(0);
        selected.setId(null);
        selected.setCompany(loginView.getAuthenticatedUser().getCompany());
        createItems.add(selected);
        initializeEmbeddableKey();
        return selected;
    }

    public ItemTransactions prepareCreateInCreate() {

        selected1 = new ItemTransactions();
        selected1.setCompany(loginView.getAuthenticatedUser().getCompany());
        createItems = preparingTempId(selected1, createItems);
        initializeEmbeddableKey();
        return selected1;
    }

    public ItemTransactions prepareCreate1() {
        selected = new ItemTransactions();
        int tempId = 0;
        for (ItemTransactions p : createItems) {
            if (p.getTempId() > tempId) {
                tempId = p.getTempId();
            }
        }
        selected.setCompany(loginView.getAuthenticatedUser().getCompany());
        selected.setTempId(tempId + 1);
        createItems.add(selected);
        return selected;
    }

    public ItemTransactions prepareCreateInEdit() {

        selected1 = new ItemTransactions();
        selected1.setCompany(loginView.getAuthenticatedUser().getCompany());
        editItems = preparingTempId(selected1, editItems);
        initializeEmbeddableKey();
        return selected1;
    }

    public void prepareEdit() {
        editItems = new ArrayList<>();
        selected = multiselectionItems.get(0);
        editItems.add(selected);
    }

    public String saveAndClose(String linkName) {
        cancelUpdate();
        cancelCreate();
        linkName += ".xhtml?faces-redirect=true";
        return linkName;
    }

    public String saveAndAddNew(String linkName) {
        createItems = new ArrayList<>();
        createItems.add(new ItemTransactions());
        linkName += ".xhtml?faces-redirect=true";
        return linkName;
    }

    public String saveAndAddContinue(String linkName) {
        createItems = new ArrayList<>();
        createItems.add(selected);
        linkName += ".xhtml?faces-redirect=true";
        return linkName;
    }

    public void save() {

        for (ItemTransactions item : getCreateItems()) {
            if (item.getId() == null) {
                getFacade().create(item);
            } else {
                getFacade().edit(item);
            }
        }
        if (!JsfUtil.isValidationFailed()) {
            items = null;    // Invalidate list of items to trigger re-query.
            JsfUtil.addSuccessMessage("Saved");
        }
    }

    public void saveRow() {
        for (ItemTransactions item : getEditItems()) {
            if (item.getId() == null) {
                getFacade().create(item);
            } else {
                getFacade().edit(item);
            }

        }
        if (!JsfUtil.isValidationFailed()) {
            // Invalidate list of items to trigger re-query.
            JsfUtil.addSuccessMessage("Saved");
        }
    }

    public void saveInEdit() {

        for (ItemTransactions item : getEditItems()) {
            if (item.getId() == null) {
                getFacade().create(item);
            } else {
                getFacade().edit(item);
            }
        }
        if (!JsfUtil.isValidationFailed()) {
            items = null;    // Invalidate list of items to trigger re-query.
            JsfUtil.addSuccessMessage("Saved");
        }
    }

    public void inventoryTransactions() {
        try {
            if (selected2.getTransactionType() != null) {
                boolean clr = true;
                for (ItemTransactions item : getCreateItems()) {
                    if (selected2.getTransactionType().getDetailCode().equalsIgnoreCase("A")) {
                        char incDec = item.getAdjustToIncrease() ? 'I' : 'D';
                        if (!systemConstantController.getSelected1().getApplyLocationMgmBoolean() &&
                                !systemConstantController.getSelected1().getApplyLotMgmBoolean()) {
                            List<ItemsInBranch> itemsInBranchList = itemsInBranchController.itemsAvailableSelectOneByItemAndBranch(item.getItemNumber(), selected2.getBranch());
                            if (!itemsInBranchList.isEmpty()) {
                                ItemsInBranch ib = itemsInBranchList.get(0);
                                double factor = itemUomConversionsController.fromOtherToAnother(item.getItemNumber(), item.getUnitOfMeasure(), ib.getUnitOfMeasure());
                                double qb = ib.getQuantityAvailable() == null ? 0.0 : ib.getQuantityAvailable();
                                double qI = factor * (item.getQuantityTransaction() == null ? 0.0 : Math.abs(item.getQuantityTransaction()));
                                if (qI < 0.0 && qb < Math.abs(qI)) {
                                    JsfUtil.addErrorMessage("Quantity is Greater than expected value!");
                                    clr = false;
                                    break;
                                } else {
                                    if (incDec == 'I') {
                                        ib.setQuantityAvailable(qb + qI);
                                        itemsInBranchController.saveInEdit(ib, 'A', selected2.getRemark(), null, null);
                                    } else {
                                        ib.setQuantityAvailable(qb - qI);
                                        itemsInBranchController.saveInEdit(ib, 'A', selected2.getRemark(), null, null);
                                    }
                                }
                            }
                        } else if (systemConstantController.getSelected1().getApplyLocationMgmBoolean() &&
                                !systemConstantController.getSelected1().getApplyLotMgmBoolean()) {
                            if (item.getItemLocation() != null) {
                                ItemLocations il = item.getItemLocation();
                                double qb = il.getQuantityOnHand() == null ? 0.0 : il.getQuantityOnHand();
                                UdcDetails uom = itemsInBranchController.itemBranchUoM(item.getItemNumber(), selected2.getBranch());
                                double factor = itemUomConversionsController.fromOtherToAnother(item.getItemNumber(), item.getUnitOfMeasure(), uom);
                                double qI = factor * (item.getQuantityTransaction() == null ? 0.0 : Math.abs(item.getQuantityTransaction()));
                                if (qI < 0.0 && qb < Math.abs(qI)) {
                                    JsfUtil.addErrorMessage("Quantity is Greater than expected value!");
                                    clr = false;
                                    break;
                                } else {
                                    if (incDec == 'I') {
                                        il.setQuantityOnHand(qb + qI);
                                        itemLocationsController.saveRow(il, 'A', selected2.getTransactionNumber(), selected2.getRemark(), null, null);
                                    } else if (incDec == 'D') {
                                        il.setQuantityOnHand(qb - qI);
                                        itemLocationsController.saveRow(il, 'A', selected2.getTransactionNumber(), selected2.getRemark(), null, null);
                                    }
                                }
                            }
                        } else if (systemConstantController.getSelected1().getApplyLocationMgmBoolean() &&
                                systemConstantController.getSelected1().getApplyLotMgmBoolean()) {
                            if (item.getLotNumber() != null) {
                                LotMaster lm = item.getLotNumber();
                                double qb = lm.getQuantityAvailable() == null ? 0.0 : lm.getQuantityAvailable();
                                UdcDetails uom = itemsInBranchController.itemBranchUoM(item.getItemNumber(), selected2.getBranch());
                                double factor = itemUomConversionsController.fromOtherToAnother(item.getItemNumber(), item.getUnitOfMeasure(), uom);
                                double qI = factor * (item.getQuantityTransaction() == null ? 0.0 : Math.abs(item.getQuantityTransaction()));
                                if (qI < 0.0 && qb < Math.abs(qI)) {
                                    JsfUtil.addErrorMessage("Quantity is Greater than expected value!");
                                    clr = false;
                                    break;
                                } else {
                                    if (incDec == 'I') {
                                        lm.setQuantityAvailable(qb + qI);
                                        lotMasterController.saveRow(lm, 'A', selected2.getTransactionNumber(), selected2.getRemark(), null);
                                    } else if (incDec == 'D') {
                                        lm.setQuantityAvailable(qb - qI);
                                        lotMasterController.saveRow(lm, 'A', selected2.getTransactionNumber(), selected2.getRemark(), null);
                                    }
                                }
                            }
                        }
                    } else if (selected2.getTransactionType().getDetailCode().equalsIgnoreCase("I")) {
                        if (!systemConstantController.getSelected1().getApplyLocationMgmBoolean() &&
                                !systemConstantController.getSelected1().getApplyLotMgmBoolean()) {
                            List<ItemsInBranch> itemsInBranchList = itemsInBranchController.itemsAvailableSelectOneByItemAndBranch(item.getItemNumber(), selected2.getBranch());
                            if (!itemsInBranchList.isEmpty()) {
                                ItemsInBranch ib = itemsInBranchList.get(0);
                                double qb = ib.getQuantityAvailable() == null ? 0.0 : ib.getQuantityAvailable();
                                UdcDetails uom = itemsInBranchController.itemBranchUoM(item.getItemNumber(), selected2.getBranch());
                                double factor = itemUomConversionsController.fromOtherToAnother(item.getItemNumber(), item.getUnitOfMeasure(), uom);
                                double qI = factor * (item.getQuantityTransaction() == null ? 0.0 : item.getQuantityTransaction());
                                if (qb < qI) {
                                    JsfUtil.addErrorMessage("Quantity is Greater than expected value!");
                                    clr = false;
                                    break;
                                } else {
                                    ib.setQuantityAvailable(qb - Math.abs(qI));
                                    itemsInBranchController.saveInEdit(ib, 'I', selected2.getRemark(), null, null);
                                }


                            }
                        } else if (systemConstantController.getSelected1().getApplyLocationMgmBoolean() &&
                                !systemConstantController.getSelected1().getApplyLotMgmBoolean()) {
                            if (item.getItemLocation() != null) {
                                ItemLocations il = item.getItemLocation();
                                double qb = il.getQuantityOnHand() == null ? 0.0 : il.getQuantityOnHand();
                                UdcDetails uom = itemsInBranchController.itemBranchUoM(item.getItemNumber(), selected2.getBranch());
                                double factor = itemUomConversionsController.fromOtherToAnother(item.getItemNumber(), item.getUnitOfMeasure(), uom);
                                double qI = factor * (item.getQuantityTransaction() == null ? 0.0 : item.getQuantityTransaction());
                                if (qb < qI) {
                                    JsfUtil.addErrorMessage("Quantity is Greater than expected value!");
                                    clr = false;
                                    break;
                                } else {
                                    il.setQuantityOnHand(qb - Math.abs(qI));
                                    itemLocationsController.saveRow(il, 'I', selected2.getTransactionNumber(), selected2.getRemark(), null, null);
                                }
                            }
                        } else if (systemConstantController.getSelected1().getApplyLocationMgmBoolean() &&
                                systemConstantController.getSelected1().getApplyLotMgmBoolean()) {
                            if (item.getLotNumber() != null) {
                                LotMaster lm = item.getLotNumber();
                                double qb = lm.getQuantityAvailable() == null ? 0.0 : lm.getQuantityAvailable();
                                UdcDetails uom = itemsInBranchController.itemBranchUoM(item.getItemNumber(), selected2.getBranch());
                                double factor = itemUomConversionsController.fromOtherToAnother(item.getItemNumber(), item.getUnitOfMeasure(), uom);
                                double qI = factor * (item.getQuantityTransaction() == null ? 0.0 : item.getQuantityTransaction());
                                if (qb < qI) {
                                    JsfUtil.addErrorMessage("Quantity is Greater than expected value!");
                                    clr = false;
                                    break;
                                } else {
                                    lm.setQuantityAvailable(qb - Math.abs(qI));
                                    lotMasterController.saveRow(lm, 'I', selected2.getTransactionNumber(), selected2.getRemark(), null);
                                }
                            }
                        }
                    } else if (selected2.getTransactionType().getDetailCode().equalsIgnoreCase("T")) {
                        if (!systemConstantController.getSelected1().getApplyLocationMgmBoolean() &&
                                !systemConstantController.getSelected1().getApplyLotMgmBoolean()) {
                            List<ItemsInBranch> itemsInBranchList = itemsInBranchController.itemsAvailableSelectOneByItemAndBranch(item.getItemNumber(), selected2.getBranch());
                            List<ItemsInBranch> itemsInBranchList1 = itemsInBranchController.itemsAvailableSelectOneByItemAndBranch(item.getItemNumber(), selected1.getBranch());
                            if (!itemsInBranchList.isEmpty() && !itemsInBranchList1.isEmpty()) {
                                ItemsInBranch ib = itemsInBranchList.get(0);
                                ItemsInBranch ib2 = itemsInBranchList.get(0);
                                if (!ib.getBranch().getId().equals(ib2.getBranch().getId())) {
                                    double qb = ib.getQuantityAvailable() == null ? 0.0 : ib.getQuantityAvailable();
                                    UdcDetails uomTo = itemsInBranchController.itemBranchUoM(item.getItemNumber(), selected1.getBranch());
                                    UdcDetails uomFrom = itemsInBranchController.itemBranchUoM(item.getItemNumber(), selected2.getBranch());
                                    double factorTo = itemUomConversionsController.fromOtherToAnother(item.getItemNumber(), item.getUnitOfMeasure(), uomTo);
                                    double factorFrom = itemUomConversionsController.fromOtherToAnother(item.getItemNumber(), item.getUnitOfMeasure(), uomFrom);
                                    double qITo = factorTo * (item.getQuantityTransaction() == null ? 0.0 : item.getQuantityTransaction());
                                    double qIFrom = factorFrom * (item.getQuantityTransaction() == null ? 0.0 : item.getQuantityTransaction());
                                    if (qb < qIFrom) {
                                        JsfUtil.addErrorMessage("Quantity is Greater than expected value!");
                                        clr = false;
                                        break;
                                    } else {
                                        double qb2 = ib2.getQuantityAvailable() == null ? 0.0 : ib2.getQuantityAvailable();
                                        ib.setQuantityAvailable(qb - Math.abs(qIFrom));
                                        ib2.setQuantityAvailable(qb2 + Math.abs(qITo));
                                        itemsInBranchController.saveInEdit(ib, 'T', selected2.getRemark() + " Out", null, null);
                                        itemsInBranchController.saveInEdit(ib2, 'T', selected2.getRemark() + " In", null, null);
                                    }
                                } else {
                                    JsfUtil.addErrorMessage("Transferring to same branch not allowed!");
                                    clr = false;
                                    break;
                                }
                            }
                        } else if (systemConstantController.getSelected1().getApplyLocationMgmBoolean() &&
                                !systemConstantController.getSelected1().getApplyLotMgmBoolean()) {
                            if (item.getItemLocation() != null && item.getItemLocationsTo() != null) {
                                ItemLocations il = item.getItemLocation();
                                ItemLocations il2 = item.getItemLocationsTo();
                                if (!il.getId().equals(il2.getId())) {
                                    double qb = il.getQuantityOnHand() == null ? 0.0 : il.getQuantityOnHand();
                                    UdcDetails uomTo = itemsInBranchController.itemBranchUoM(item.getItemNumber(), selected1.getBranch());
                                    UdcDetails uomFrom = itemsInBranchController.itemBranchUoM(item.getItemNumber(), selected2.getBranch());
                                    double factorTo = itemUomConversionsController.fromOtherToAnother(item.getItemNumber(), item.getUnitOfMeasure(), uomTo);
                                    double factorFrom = itemUomConversionsController.fromOtherToAnother(item.getItemNumber(), item.getUnitOfMeasure(), uomFrom);
                                    double qITo = factorTo * (item.getQuantityTransaction() == null ? 0.0 : item.getQuantityTransaction());
                                    double qIFrom = factorFrom * (item.getQuantityTransaction() == null ? 0.0 : item.getQuantityTransaction());

                                    if (qb < qIFrom) {
                                        JsfUtil.addErrorMessage("Quantity is Greater than expected value!");
                                        clr = false;
                                        break;
                                    } else {
                                        double qb2 = il2.getQuantityOnHand() == null ? 0.0 : il.getQuantityOnHand();
                                        il.setQuantityOnHand(qb - Math.abs(qIFrom));
                                        il2.setQuantityOnHand(qb2 + Math.abs(qITo));
                                        itemLocationsController.saveRow(il, 'T', selected2.getTransactionNumber(), selected2.getRemark() + " Out", null, null);
                                        itemLocationsController.saveRow(il2, 'T', selected2.getTransactionNumber(), selected2.getRemark() + " In", null, null);
                                    }
                                } else {
                                    JsfUtil.addErrorMessage("Transferring to same location not allowed!");
                                    clr = false;
                                    break;
                                }
                            }
                        } else if (systemConstantController.getSelected1().getApplyLocationMgmBoolean() &&
                                systemConstantController.getSelected1().getApplyLotMgmBoolean()) {
                            if (item.getLotNumber() != null) {
                                LotMaster lm = item.getLotNumber();
                                LotMaster lm2 = new LotMaster();
                                lm2.setLotNumber(lm.getLotNumber());
                                lm2.setUnitPrice(lm.getUnitPrice());
                                lm2.setDateEffective(lm.getDateEffective());
                                lm2.setDateExpiration(lm.getDateExpiration());
                                lm2.setBatchNumberSupplier(lm.getBatchNumberSupplier());
                                lm2.setCompany(lm.getCompany());
                                lm2.setItemNumber(lm.getItemNumber());
                                lm2.setBranch(selected1.getBranch());
                                lm2.setLotStatus(lm.getLotStatus());
                                if (!item.getItemLocation().getId().equals(item.getItemLocationsTo().getId())) {
//                                    lm2.setId(null);
                                    lm2.setLocation(item.getItemLocationsTo());
                                    double qb = lm.getQuantityAvailable() == null ? 0.0 : lm.getQuantityAvailable();
                                    UdcDetails uomTo = itemsInBranchController.itemBranchUoM(item.getItemNumber(), selected1.getBranch());
                                    UdcDetails uomFrom = itemsInBranchController.itemBranchUoM(item.getItemNumber(), selected2.getBranch());
                                    double factorTo = itemUomConversionsController.fromOtherToAnother(item.getItemNumber(), item.getUnitOfMeasure(), uomTo);
                                    double factorFrom = itemUomConversionsController.fromOtherToAnother(item.getItemNumber(), item.getUnitOfMeasure(), uomFrom);
                                    double qITo = factorTo * (item.getQuantityTransaction() == null ? 0.0 : item.getQuantityTransaction());
                                    double qIFrom = factorFrom * (item.getQuantityTransaction() == null ? 0.0 : item.getQuantityTransaction());
                                    if (qb < qIFrom) {
                                        JsfUtil.addErrorMessage("Quantity is Greater than expected value!");
                                        clr = false;
                                        break;
                                    } else {
                                        lm.setQuantityAvailable(qb - Math.abs(qIFrom));
                                        lm2.setQuantityAvailable(Math.abs(qITo));
                                        lotMasterController.saveRow(lm, 'T', selected2.getTransactionNumber(), selected2.getRemark() + " Out", null);
                                        lotMasterController.saveRow(lm2, 'T', selected2.getTransactionNumber(), selected2.getRemark() + " In", null);
                                    }
                                } else {
                                    JsfUtil.addErrorMessage("Transferring to same location not allowed!");
                                    clr = false;
                                    break;
                                }
                            }
                        }
                    }
                }
                if (clr) {
                    JsfUtil.addSuccessMessage("Transaction Successfully Created!");
                    prepareCreate();
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
            JsfUtil.addErrorMessage("Error Occurred, Please Contact Vendor!");
        }
    }

    public double oppeningAmount(ItemsTable it, BranchTable br, Date dateFrom, Date dateThru) {
        double qOpen = 0.0;
        try {
//            && dateThru.compareTo(dateFrom) <= 0
            if (it != null && dateFrom != null && dateThru != null) {
                LocalDate fromLocal = Instant.ofEpochMilli(dateFrom.getTime())
                        .atZone(ZoneId.systemDefault())
                        .toLocalDate();
                LocalDate thruLocal = Instant.ofEpochMilli(dateThru.getTime())
                        .atZone(ZoneId.systemDefault())
                        .toLocalDate();
                Date fromDateTime = Date.from(fromLocal.atStartOfDay(ZoneId.systemDefault()).toInstant());
                Date thruDateTime = Date.from(thruLocal.atTime(LocalTime.MAX).atZone(ZoneId.systemDefault()).toInstant());
                if (br != null) {
                    ItemsInBranch ib = itemsInBranchController.itemBranchByItemAndBranch(it, br);
                    TypedQuery<ItemTransactions> qb = em.createQuery(
                            "SELECT i " +
                                    "FROM ItemTransactions i " +
                                    "WHERE i.company = :company " +
                                    "AND i.itemNumber.id = :itemNumber " +
                                    "AND i.branch.id = :branch " +
                                    "AND i.dateCreated BETWEEN :dateFrom AND :dateThru " +
                                    "AND i.beforeAmountCost IS NOT NULL",
                            ItemTransactions.class);
                    qb.setParameter("company", loginView.getAuthenticatedUser().getCompany());
                    qb.setParameter("itemNumber", it.getId());
                    qb.setParameter("branch", br.getId());
                    qb.setParameter("dateFrom", fromDateTime);
                    qb.setParameter("dateThru", thruDateTime);
                    List<ItemTransactions> itemTransactionsList = qb.getResultList().stream().sorted(Comparator.comparing(ItemTransactions::getDateCreated)).collect(Collectors.toList());
                    if (itemTransactionsList.isEmpty()) {
                        //Find Before Any Transactio:
                        qb = em.createQuery(
                                "SELECT i " +
                                        "FROM ItemTransactions i " +
                                        "WHERE i.company = :company " +
                                        "AND i.itemNumber.id = :itemNumber " +
                                        "AND i.branch.id = :branch " +
                                        "AND i.dateCreated < :dateFrom " +
                                        "AND i.beforeAmountCost IS NOT NULL",
                                ItemTransactions.class);
                        qb.setParameter("company", loginView.getAuthenticatedUser().getCompany());
                        qb.setParameter("itemNumber", it.getId());
                        qb.setParameter("branch", br.getId());
                        qb.setParameter("dateFrom", fromDateTime);
                        itemTransactionsList = qb.getResultList().stream().sorted(Comparator.comparing(ItemTransactions::getDateCreated).reversed()).collect(Collectors.toList());
                    }
                    if (itemTransactionsList.isEmpty()) {
                        //Still Empty, find after:
                        qb = em.createQuery(
                                "SELECT i " +
                                        "FROM ItemTransactions i " +
                                        "WHERE i.company = :company " +
                                        "AND i.itemNumber.id = :itemNumber " +
                                        "AND i.branch.id = :branch " +
                                        "AND i.dateCreated > :dateThru " +
                                        "AND i.beforeAmountCost IS NOT NULL",
                                ItemTransactions.class);
                        qb.setParameter("company", loginView.getAuthenticatedUser().getCompany());
                        qb.setParameter("itemNumber", it.getId());
                        qb.setParameter("branch", br.getId());
                        qb.setParameter("dateThru", thruDateTime);
                        itemTransactionsList = qb.getResultList().stream().sorted(Comparator.comparing(ItemTransactions::getDateCreated).reversed()).collect(Collectors.toList());
                    }
                    if (itemTransactionsList.isEmpty() && itemCostTableController.itemCostTableByItem(it) != null) {
                        //Still Empty, take current Available:
                    double factor = itemUomConversionsController.fromOtherToPrimary(it, ib.getUnitOfMeasure());
                    double unitCost = itemCostTableController.itemCostTableByItem(it).getAmountUnitCost();
                        qOpen = Math.abs(factor * unitCost);
                    } else {
                        qOpen = Math.abs(itemTransactionsList.isEmpty() ? 0.0 : itemTransactionsList.get(0).getBeforeAmountCost());
                    }
                } else {
                    List<ItemsInBranch> itemsInBranchList = itemsInBranchController.itemInBranchByItem(it);
                    for (ItemsInBranch ib : itemsInBranchList) {
                        TypedQuery<ItemTransactions> qb = em.createQuery(
                                "SELECT i " +
                                        "FROM ItemTransactions i " +
                                        "WHERE i.company = :company " +
                                        "AND i.itemNumber.id = :itemNumber " +
                                        "AND i.branch.id = :branch " +
                                        "AND i.dateCreated BETWEEN :dateFrom AND :dateThru " +
                                        "AND i.beforeAmountCost IS NOT NULL",
                                ItemTransactions.class);
                        qb.setParameter("company", loginView.getAuthenticatedUser().getCompany());
                        qb.setParameter("itemNumber", it.getId());
                        qb.setParameter("branch", ib.getBranch().getId());
                        qb.setParameter("dateFrom", fromDateTime);
                        qb.setParameter("dateThru", thruDateTime);
                        List<ItemTransactions> itemTransactionsListRC = qb.getResultList();
                        List<ItemTransactions> itemTransactionsList = itemTransactionsListRC.stream().sorted(Comparator.comparing(ItemTransactions::getDateCreated)).collect(Collectors.toList());
                        if (itemTransactionsList.isEmpty()) {
                            //Find Before Any Transactio:
                            qb = em.createQuery(
                                    "SELECT i " +
                                            "FROM ItemTransactions i " +
                                            "WHERE i.company = :company " +
                                            "AND i.itemNumber.id = :itemNumber " +
                                            "AND i.branch.id = :branch " +
                                            "AND i.dateCreated < :dateFrom " +
                                            "AND i.beforeAmountCost IS NOT NULL",
                                    ItemTransactions.class);
                            qb.setParameter("company", loginView.getAuthenticatedUser().getCompany());
                            qb.setParameter("itemNumber", it.getId());
                            qb.setParameter("branch", ib.getId());
                            qb.setParameter("dateFrom", fromDateTime);
                            itemTransactionsList = qb.getResultList().stream().sorted(Comparator.comparing(ItemTransactions::getDateCreated).reversed()).collect(Collectors.toList());
                        }
                        if (itemTransactionsList.isEmpty()) {
                            //Still Empty, find after:
                            qb = em.createQuery(
                                    "SELECT i " +
                                            "FROM ItemTransactions i " +
                                            "WHERE i.company = :company " +
                                            "AND i.itemNumber.id = :itemNumber " +
                                            "AND i.branch.id = :branch " +
                                            "AND i.dateCreated > :dateThru " +
                                            "AND i.beforeAmountCost IS NOT NULL",
                                    ItemTransactions.class);
                            qb.setParameter("company", loginView.getAuthenticatedUser().getCompany());
                            qb.setParameter("itemNumber", it.getId());
                            qb.setParameter("branch", ib.getId());
                            qb.setParameter("dateThru", thruDateTime);
                            itemTransactionsList = qb.getResultList().stream().sorted(Comparator.comparing(ItemTransactions::getDateCreated).reversed()).collect(Collectors.toList());
                        }
                        if (itemTransactionsList.isEmpty() && itemCostTableController.itemCostTableByItem(it) != null) {
                            //Still Empty, take current Available:
                            double factor = itemUomConversionsController.fromOtherToPrimary(it, ib.getUnitOfMeasure());
                            double unitCost = itemCostTableController.itemCostTableByItem(it).getAmountUnitCost();
                            qOpen =+ Math.abs(factor * unitCost);
                        } else {
                            qOpen =+ Math.abs(itemTransactionsList.isEmpty() ? 0.0 : itemTransactionsList.get(0).getBeforeAmountCost());
                        }
                    }
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
            JsfUtil.addErrorMessage("Error Occurred, Please Contact Vendor!");
        }
        return qOpen;
    }

    public double getTotalOpeening() {
        totalOpeening = 0.0;
        for(ItemsTable it:itemsTableController.getItems()){
            totalOpeening +=  oppeningAmount(it,null,salesOrderHeaderController.getStartdateForSales(),salesOrderHeaderController.getThrudateForSales());
        }
        return totalOpeening;
    }

    public void setTotalOpeening(double totalOpeening) {
        this.totalOpeening = totalOpeening;
    }

    public double oppeningTotalAmount(ItemsTable it, BranchTable br, Date dateFrom, Date dateThru) {
        double totalAmnt = 0.0;
        try {
//            if (it != null && dateFrom != null && dateThru != null) {
//                LocalDate fromLocal = Instant.ofEpochMilli(dateFrom.getTime())
//                        .atZone(ZoneId.systemDefault())
//                        .toLocalDate();
//                LocalDate thruLocal = Instant.ofEpochMilli(dateThru.getTime())
//                        .atZone(ZoneId.systemDefault())
//                        .toLocalDate();
//                Date fromDateTime = Date.from(fromLocal.atStartOfDay(ZoneId.systemDefault()).toInstant());
//                Date thruDateTime = Date.from(thruLocal.atTime(LocalTime.MAX).atZone(ZoneId.systemDefault()).toInstant());
//                if (br != null) {
//                    TypedQuery<ItemTransactions> qb = em.createQuery(
//                            "SELECT i " +
//                                    "FROM ItemTransactions i " +
//                                    "WHERE i.company = :company " +
//                                    "AND i.itemNumber.id = :itemNumber " +
//                                    "AND i.branch.id = :branch " +
//                                    "AND i.dateCreated BETWEEN :dateFrom AND :dateThru " +
//                                    "AND i.amountCost IS NOT NULL " +
//                                    "AND i.orderType.recordHeader.udcCode = 'OT' " +
//                                    "AND i.orderType.detailCode = 'S'",
//                            ItemTransactions.class);
//                    qb.setParameter("company", loginView.getAuthenticatedUser().getCompany());
//                    qb.setParameter("itemNumber", it.getId());
//                    qb.setParameter("branch", br.getId());
//                    qb.setParameter("dateFrom", fromDateTime);
//                    qb.setParameter("dateThru", thruDateTime);
//                    totalAmnt =  qb.getResultList().stream().mapToDouble(e->Math.abs(e.getAmountCost())).sum();
//                } else {
//                    List<ItemsInBranch> itemsInBranchList = itemsInBranchController.itemInBranchByItem(it);
//                    for (ItemsInBranch ib : itemsInBranchList) {
//                        TypedQuery<ItemTransactions> qb = em.createQuery(
//                                "SELECT i " +
//                                        "FROM ItemTransactions i " +
//                                        "WHERE i.company = :company " +
//                                        "AND i.itemNumber.id = :itemNumber " +
//                                        "AND i.branch.id = :branch " +
//                                        "AND i.dateCreated BETWEEN :dateFrom AND :dateThru " +
//                                        "AND i.beforeStoreQuantityAvailable IS NOT NULL "  +
//                                        "AND i.orderType.recordHeader.udcCode = 'OT' " +
//                                        "AND i.orderType.detailCode = 'S'",
//                                ItemTransactions.class);
//                        qb.setParameter("company", loginView.getAuthenticatedUser().getCompany());
//                        qb.setParameter("itemNumber", it.getId());
//                        qb.setParameter("branch", ib.getBranch().getId());
//                        qb.setParameter("dateFrom", fromDateTime);
//                        qb.setParameter("dateThru", thruDateTime);
//                        totalAmnt += qb.getResultList().stream().mapToDouble(e->Math.abs(e.getAmountCost())).sum();
//                    }
//                }
//            }
        } catch (Exception e) {
            e.printStackTrace();
            JsfUtil.addErrorMessage("Error Occurred, Please Contact Vendor!");
        }

        return totalAmnt;

    }

    public void createInEdit() {
        getFacade().create(selected1);
        if (!JsfUtil.isValidationFailed()) {
            items = null;    // Invalidate list of items to trigger re-query.
        }
    }

    public void update() {
        persist(PersistAction.UPDATE);
    }

    public void removeInCreate(ItemTransactions item) {

        if (item.getId() == null) {
            createItems.removeIf(eachElement -> eachElement.getTempId().equals(item.getTempId()));
        } else {
            createItems.removeIf(eachElement -> eachElement.getId().equals(item.getId()));
            getFacade().remove(item);
        }

    }

    public void removeInEdit(ItemTransactions item) {

        if (item.getId() == null) {
            editItems.removeIf(eachElement -> eachElement.getTempId().equals(item.getTempId()));
        } else {
            editItems.removeIf(eachElement -> eachElement.getId().equals(item.getId()));
            getFacade().remove(item);
        }

    }

    public void removeRecord(ItemTransactions item) {

        if (item.getId() != null) {
            getFacade().remove(item);
        }

    }

    public void removeList(List<ItemTransactions> aList) {

        if (aList != null && !aList.isEmpty()) {
            getFacade().removeCollection(aList);
        }

    }

    public void destroy() {
        persist(PersistAction.DELETE);
        if (!JsfUtil.isValidationFailed()) {
            selected = null; // Remove selection
            items = null;    // Invalidate list of items to trigger re-query.
            multiselectionItems = null;
        }
    }

    public List<ItemTransactions> getItems() {
        if (items == null) {
            TypedQuery<ItemTransactions> q = em.createQuery(
                    "SELECT i " +
                            "FROM ItemTransactions i " +
                            "WHERE i.company = :company ",
                    ItemTransactions.class);

            q.setParameter("company", loginView.getAuthenticatedUser().getCompany());          // company is the Company entity or its ID, see below
            items = q.getResultList();
        }
        items = items.stream().filter(i -> i.getCompany() != null && i.getCompany().getId().equals(loginView.getAuthenticatedUser().getCompany().getId()))
                .collect(Collectors.toList());
        return items;
    }

    public void setItems(List<ItemTransactions> items) {
        this.items = items;
    }

    public List<ItemTransactions> getMultiselectionItems() {
        return multiselectionItems;
    }

    public void setMultiselectionItems(List<ItemTransactions> multiselectionItems) {
        this.multiselectionItems = multiselectionItems;
    }

    public List<ItemTransactions> getFilteredValues() {
        return filteredValues;
    }

    public void setFilteredValues(List<ItemTransactions> filteredValues) {
        this.filteredValues = filteredValues;
    }

    public List<ItemTransactions> getCreateItems() {
        if (createItems == null) {
            TypedQuery<ItemTransactions> q = em.createQuery(
                    "SELECT i " +
                            "FROM ItemTransactions i " +
                            "WHERE i.company = :company ",
                    ItemTransactions.class);

            q.setParameter("company", loginView.getAuthenticatedUser().getCompany());          // company is the Company entity or its ID, see below
            createItems = q.getResultList();
        }
        createItems = createItems.stream().filter(i -> i.getCompany() != null && i.getCompany().getId().equals(loginView.getAuthenticatedUser().getCompany().getId()))
                .collect(Collectors.toList());
        return createItems;
    }

    public void setCreateItems(List<ItemTransactions> createItems) {
        this.createItems = createItems;
    }

    public List<ItemTransactions> getEditItems() {
        if (editItems == null) {
            TypedQuery<ItemTransactions> q = em.createQuery(
                    "SELECT i " +
                            "FROM ItemTransactions i " +
                            "WHERE i.company = :company ",
                    ItemTransactions.class);

            q.setParameter("company", loginView.getAuthenticatedUser().getCompany());          // company is the Company entity or its ID, see below
            editItems = q.getResultList();
        }
        editItems = editItems.stream().filter(i -> i.getCompany() != null && i.getCompany().getId().equals(loginView.getAuthenticatedUser().getCompany().getId()))
                .collect(Collectors.toList());
        return editItems;
    }

    public void setEditItems(List<ItemTransactions> editItems) {
        this.editItems = editItems;
    }

    private List<ItemTransactions> preparingTempId(ItemTransactions item, List<ItemTransactions> aList) {
        int tempId = 0;
        if (!aList.isEmpty()) {
            for (ItemTransactions itm : aList) {
                if (itm.getTempId() != null && itm.getTempId() > tempId) {
                    tempId = itm.getTempId();
                }
            }
        }
        tempId += 1;
        item.setTempId(tempId);
        aList.add(item);
        return aList;
    }

    private void persist(PersistAction persistAction) {
        if (!multiselectionItems.isEmpty()) {
            for (ItemTransactions item : multiselectionItems) {
                setEmbeddableKeys();
                try {
                    if (persistAction != PersistAction.DELETE) {
                        getFacade().edit(item);
                    } else {
                        getFacade().remove(item);
                    }

                } catch (EJBException ex) {
                    String msg = "";
                    Throwable cause = ex.getCause();
                    if (cause != null) {
                        msg = cause.getLocalizedMessage();
                    }
                    if (msg.length() > 0) {
                        JsfUtil.addErrorMessage(msg);
                    } else {
                        JsfUtil.addErrorMessage(ex, ResourceBundle.getBundle("/Bundle").getString("PersistenceErrorOccured"));
                    }
                } catch (Exception ex) {
                    Logger.getLogger(this.getClass().getName()).log(Level.SEVERE, null, ex);
                    JsfUtil.addErrorMessage(ex, ResourceBundle.getBundle("/Bundle").getString("PersistenceErrorOccured"));
                }
            }
        }
    }

    public ItemTransactions getItemTransactions(java.lang.Integer id) {
        return getFacade().find(id);
    }

    public List<ItemTransactions> getItemsAvailableSelectMany() {
        TypedQuery<ItemTransactions> q = em.createQuery(
                "SELECT i " +
                        "FROM ItemTransactions i " +
                        "WHERE i.company = :company ",
                ItemTransactions.class);

        q.setParameter("company", loginView.getAuthenticatedUser().getCompany());          // company is the Company entity or its ID, see below
        return q.getResultList();
    }

    public List<ItemTransactions> getItemsAvailableSelectOne() {
        TypedQuery<ItemTransactions> q = em.createQuery(
                "SELECT i " +
                        "FROM ItemTransactions i " +
                        "WHERE i.company = :company ",
                ItemTransactions.class);

        q.setParameter("company", loginView.getAuthenticatedUser().getCompany());          // company is the Company entity or its ID, see below
        return q.getResultList();
    }

    @FacesConverter(forClass = ItemTransactions.class)
    public static class ItemTransactionsControllerConverter implements Converter {

        @Override
        public Object getAsObject(FacesContext facesContext, UIComponent component, String value) {
            if (value == null || value.length() == 0) {
                return null;
            }
            ItemTransactionsController controller = (ItemTransactionsController) facesContext.getApplication().getELResolver().
                    getValue(facesContext.getELContext(), null, "itemTransactionsController");
            return controller.getItemTransactions(getKey(value));
        }

        java.lang.Integer getKey(String value) {
            java.lang.Integer key;
            key = Integer.valueOf(value);
            return key;
        }

        String getStringKey(java.lang.Integer value) {
            StringBuilder sb = new StringBuilder();
            sb.append(value);
            return sb.toString();
        }

        @Override
        public String getAsString(FacesContext facesContext, UIComponent component, Object object) {
            if (object == null) {
                return null;
            }
            if (object instanceof ItemTransactions) {
                ItemTransactions o = (ItemTransactions) object;
                return getStringKey(o.getId());
            } else {
                Logger.getLogger(this.getClass().getName()).log(Level.SEVERE, "object {0} is of type {1}; expected type: {2}", new Object[]{object, object.getClass().getName(), ItemTransactions.class.getName()});
                return null;
            }
        }

    }

}
