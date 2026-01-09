package org.acme.e2e;

import static io.restassured.RestAssured.get;
import static io.restassured.RestAssured.given;
import static org.hamcrest.Matchers.greaterThanOrEqualTo;
import static org.hamcrest.Matchers.is;

import java.math.BigDecimal;

import jakarta.ws.rs.core.Response.Status;

import org.junit.jupiter.api.MethodOrderer.OrderAnnotation;
import org.junit.jupiter.api.Order;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.TestMethodOrder;

import io.quarkus.test.junit.QuarkusTest;
import io.quarkus.test.junit5.virtual.ShouldNotPin;
import io.quarkus.test.junit5.virtual.VirtualThreadUnit;

import io.restassured.http.ContentType;

// Note: There isn't an equivalent of this test in the Spring projects. It tests the entire application, without mocking.
// The tests run in test mode, in the same process as the application under test.
@QuarkusTest
@TestMethodOrder(OrderAnnotation.class)
@VirtualThreadUnit
@ShouldNotPin
public class FruitControllerEndToEndTest {
  private static final int DEFAULT_ORDER = 1;

  @Test
  @Order(DEFAULT_ORDER)
  public void getAll() {
    get("/fruits").then()
        .statusCode(Status.OK.getStatusCode())
        .contentType(ContentType.JSON)
        .body("$.size()", is(10))
        .body("[0].id", greaterThanOrEqualTo(1))
        .body("[0].name", is("Apple"))
        .body("[0].description", is("Hearty fruit"))
        .body("[0].storePrices[0].price", is(BigDecimal.valueOf(1.29).floatValue()))
        .body("[0].storePrices[0].store.name", is("Store 1"))
        .body("[0].storePrices[0].store.address.address", is("123 Main St"))
        .body("[0].storePrices[0].store.address.city", is("Anytown"))
        .body("[0].storePrices[0].store.address.country", is("USA"))
        .body("[0].storePrices[0].store.currency", is("USD"))
        .body("[0].storePrices[1].price", is(BigDecimal.valueOf(2.49).floatValue()))
        .body("[0].storePrices[1].store.name", is("Store 2"))
        .body("[0].storePrices[1].store.address.address", is("456 Main St"))
        .body("[0].storePrices[1].store.address.city", is("Paris"))
        .body("[0].storePrices[1].store.address.country", is("France"))
        .body("[0].storePrices[1].store.currency", is("EUR"))
        .body("[1].id", greaterThanOrEqualTo(1))
        .body("[1].name", is("Pear"))
        .body("[1].description", is("Juicy fruit"))
        .body("[1].storePrices[0].price", is(BigDecimal.valueOf(0.99).floatValue()))
        .body("[1].storePrices[0].store.name", is("Store 1"))
        .body("[1].storePrices[0].store.address.address", is("123 Main St"))
        .body("[1].storePrices[0].store.address.city", is("Anytown"))
        .body("[1].storePrices[0].store.address.country", is("USA"))
        .body("[1].storePrices[0].store.currency", is("USD"))
        .body("[1].storePrices[1].price", is(BigDecimal.valueOf(1.19).floatValue()))
        .body("[1].storePrices[1].store.name", is("Store 2"))
        .body("[1].storePrices[1].store.address.address", is("456 Main St"))
        .body("[1].storePrices[1].store.address.city", is("Paris"))
        .body("[1].storePrices[1].store.address.country", is("France"))
        .body("[1].storePrices[1].store.currency", is("EUR"))
        .body("[1].id", greaterThanOrEqualTo(1))
        .body("[1].name", is("Pear"))
        .body("[1].description", is("Juicy fruit"))
        .body("[1].storePrices[0].price", is(BigDecimal.valueOf(0.99).floatValue()))
        .body("[1].storePrices[0].store.name", is("Store 1"))
        .body("[1].storePrices[0].store.address.address", is("123 Main St"))
        .body("[1].storePrices[0].store.address.city", is("Anytown"))
        .body("[1].storePrices[0].store.address.country", is("USA"))
        .body("[1].storePrices[0].store.currency", is("USD"))
        .body("[1].storePrices[1].price", is(BigDecimal.valueOf(1.19).floatValue()))
        .body("[1].storePrices[1].store.name", is("Store 2"))
        .body("[1].storePrices[1].store.address.address", is("456 Main St"))
        .body("[1].storePrices[1].store.address.city", is("Paris"))
        .body("[1].storePrices[1].store.address.country", is("France"))
        .body("[1].storePrices[1].store.currency", is("EUR"))
        .body("[2].id", greaterThanOrEqualTo(1))
        .body("[2].name", is("Banana"))
        .body("[2].description", is("Tropical yellow fruit"))
        .body("[2].storePrices[0].price", is(BigDecimal.valueOf(0.59).floatValue()))
        .body("[2].storePrices[0].store.name", is("Store 1"))
        .body("[2].storePrices[0].store.address.address", is("123 Main St"))
        .body("[2].storePrices[0].store.address.city", is("Anytown"))
        .body("[2].storePrices[0].store.address.country", is("USA"))
        .body("[2].storePrices[0].store.currency", is("USD"))
        .body("[2].storePrices[1].price", is(BigDecimal.valueOf(0.89).floatValue()))
        .body("[2].storePrices[1].store.name", is("Store 2"))
        .body("[2].storePrices[1].store.address.address", is("456 Main St"))
        .body("[2].storePrices[1].store.address.city", is("Paris"))
        .body("[2].storePrices[1].store.address.country", is("France"))
        .body("[2].storePrices[1].store.currency", is("EUR"))
        .body("[3].id", greaterThanOrEqualTo(1))
        .body("[3].name", is("Orange"))
        .body("[3].description", is("Citrus fruit rich in vitamin C"))
        .body("[3].storePrices[0].price", is(BigDecimal.valueOf(1.19).floatValue()))
        .body("[3].storePrices[0].store.name", is("Store 1"))
        .body("[3].storePrices[0].store.address.address", is("123 Main St"))
        .body("[3].storePrices[0].store.address.city", is("Anytown"))
        .body("[3].storePrices[0].store.address.country", is("USA"))
        .body("[3].storePrices[0].store.currency", is("USD"))
        .body("[3].storePrices[1].price", is(BigDecimal.valueOf(1.79).floatValue()))
        .body("[3].storePrices[1].store.name", is("Store 2"))
        .body("[3].storePrices[1].store.address.address", is("456 Main St"))
        .body("[3].storePrices[1].store.address.city", is("Paris"))
        .body("[3].storePrices[1].store.address.country", is("France"))
        .body("[3].storePrices[1].store.currency", is("EUR"))
        .body("[4].id", greaterThanOrEqualTo(1))
        .body("[4].name", is("Strawberry"))
        .body("[4].description", is("Sweet red berry"))
        .body("[4].storePrices[0].price", is(BigDecimal.valueOf(3.99).floatValue()))
        .body("[4].storePrices[0].store.name", is("Store 1"))
        .body("[4].storePrices[0].store.address.address", is("123 Main St"))
        .body("[4].storePrices[0].store.address.city", is("Anytown"))
        .body("[4].storePrices[0].store.address.country", is("USA"))
        .body("[4].storePrices[0].store.currency", is("USD"))
        .body("[4].storePrices[1].price", is(BigDecimal.valueOf(3.49).floatValue()))
        .body("[4].storePrices[1].store.name", is("Store 3"))
        .body("[4].storePrices[1].store.address.address", is("789 Oak Ave"))
        .body("[4].storePrices[1].store.address.city", is("London"))
        .body("[4].storePrices[1].store.address.country", is("UK"))
        .body("[4].storePrices[1].store.currency", is("GBP"))
        .body("[5].id", greaterThanOrEqualTo(1))
        .body("[5].name", is("Mango"))
        .body("[5].description", is("Exotic tropical fruit"))
        .body("[5].storePrices[0].price", is(BigDecimal.valueOf(2.99).floatValue()))
        .body("[5].storePrices[0].store.name", is("Store 2"))
        .body("[5].storePrices[0].store.address.address", is("456 Main St"))
        .body("[5].storePrices[0].store.address.city", is("Paris"))
        .body("[5].storePrices[0].store.address.country", is("France"))
        .body("[5].storePrices[0].store.currency", is("EUR"))
        .body("[5].storePrices[1].price", is(BigDecimal.valueOf(3.99).floatValue()))
        .body("[5].storePrices[1].store.name", is("Store 6"))
        .body("[5].storePrices[1].store.address.address", is("888 Pine St"))
        .body("[5].storePrices[1].store.address.city", is("Sydney"))
        .body("[5].storePrices[1].store.address.country", is("Australia"))
        .body("[5].storePrices[1].store.currency", is("AUD"))
        .body("[6].id", greaterThanOrEqualTo(1))
        .body("[6].name", is("Grape"))
        .body("[6].description", is("Small purple or green fruit"))
        .body("[6].storePrices[0].price", is(BigDecimal.valueOf(2.79).floatValue()))
        .body("[6].storePrices[0].store.name", is("Store 3"))
        .body("[6].storePrices[0].store.address.address", is("789 Oak Ave"))
        .body("[6].storePrices[0].store.address.city", is("London"))
        .body("[6].storePrices[0].store.address.country", is("UK"))
        .body("[6].storePrices[0].store.currency", is("GBP"))
        .body("[6].storePrices[1].price", is(BigDecimal.valueOf(2.49).floatValue()))
        .body("[6].storePrices[1].store.name", is("Store 7"))
        .body("[6].storePrices[1].store.address.address", is("999 Elm Rd"))
        .body("[6].storePrices[1].store.address.city", is("Berlin"))
        .body("[6].storePrices[1].store.address.country", is("Germany"))
        .body("[6].storePrices[1].store.currency", is("EUR"))
        .body("[7].id", greaterThanOrEqualTo(1))
        .body("[7].name", is("Pineapple"))
        .body("[7].description", is("Large tropical fruit"))
        .body("[7].storePrices[0].price", is(BigDecimal.valueOf(599.99).floatValue()))
        .body("[7].storePrices[0].store.name", is("Store 4"))
        .body("[7].storePrices[0].store.address.address", is("321 Cherry Ln"))
        .body("[7].storePrices[0].store.address.city", is("Tokyo"))
        .body("[7].storePrices[0].store.address.country", is("Japan"))
        .body("[7].storePrices[0].store.currency", is("JPY"))
        .body("[7].storePrices[1].price", is(BigDecimal.valueOf(5.49).floatValue()))
        .body("[7].storePrices[1].store.name", is("Store 6"))
        .body("[7].storePrices[1].store.address.address", is("888 Pine St"))
        .body("[7].storePrices[1].store.address.city", is("Sydney"))
        .body("[7].storePrices[1].store.address.country", is("Australia"))
        .body("[7].storePrices[1].store.currency", is("AUD"))
        .body("[7].storePrices[2].price", is(BigDecimal.valueOf(49.99).floatValue()))
        .body("[7].storePrices[2].store.name", is("Store 8"))
        .body("[7].storePrices[2].store.address.address", is("147 Birch Blvd"))
        .body("[7].storePrices[2].store.address.city", is("Mexico City"))
        .body("[7].storePrices[2].store.address.country", is("Mexico"))
        .body("[7].storePrices[2].store.currency", is("MXN"))
        .body("[8].id", greaterThanOrEqualTo(1))
        .body("[8].name", is("Watermelon"))
        .body("[8].description", is("Large refreshing summer fruit"))
        .body("[8].storePrices[0].price", is(BigDecimal.valueOf(6.99).floatValue()))
        .body("[8].storePrices[0].store.name", is("Store 5"))
        .body("[8].storePrices[0].store.address.address", is("555 Maple Dr"))
        .body("[8].storePrices[0].store.address.city", is("Toronto"))
        .body("[8].storePrices[0].store.address.country", is("Canada"))
        .body("[8].storePrices[0].store.currency", is("CAD"))
        .body("[8].storePrices[1].price", is(BigDecimal.valueOf(4.99).floatValue()))
        .body("[8].storePrices[1].store.name", is("Store 7"))
        .body("[8].storePrices[1].store.address.address", is("999 Elm Rd"))
        .body("[8].storePrices[1].store.address.city", is("Berlin"))
        .body("[8].storePrices[1].store.address.country", is("Germany"))
        .body("[8].storePrices[1].store.currency", is("EUR"))
        .body("[9].id", greaterThanOrEqualTo(1))
        .body("[9].name", is("Kiwi"))
        .body("[9].description", is("Small fuzzy green fruit"))
        .body("[9].storePrices[0].price", is(BigDecimal.valueOf(1.99).floatValue()))
        .body("[9].storePrices[0].store.name", is("Store 6"))
        .body("[9].storePrices[0].store.address.address", is("888 Pine St"))
        .body("[9].storePrices[0].store.address.city", is("Sydney"))
        .body("[9].storePrices[0].store.address.country", is("Australia"))
        .body("[9].storePrices[0].store.currency", is("AUD"));
  }

  @Test
  @Order(DEFAULT_ORDER)
  public void getFruitFound() {
    get("/fruits/Apple").then()
        .statusCode(Status.OK.getStatusCode())
        .contentType(ContentType.JSON)
        .body("id", greaterThanOrEqualTo(1))
        .body("name", is("Apple"))
        .body("description", is("Hearty fruit"))
        .body("storePrices[0].price", is(BigDecimal.valueOf(1.29).floatValue()))
        .body("storePrices[0].store.name", is("Store 1"))
        .body("storePrices[0].store.address.address", is("123 Main St"))
        .body("storePrices[0].store.address.city", is("Anytown"))
        .body("storePrices[0].store.address.country", is("USA"))
        .body("storePrices[0].store.currency", is("USD"))
        .body("storePrices[1].price", is(BigDecimal.valueOf(2.49).floatValue()))
        .body("storePrices[1].store.name", is("Store 2"))
        .body("storePrices[1].store.address.address", is("456 Main St"))
        .body("storePrices[1].store.address.city", is("Paris"))
        .body("storePrices[1].store.address.country", is("France"))
        .body("storePrices[1].store.currency", is("EUR"));
  }

  @Test
  @Order(DEFAULT_ORDER)
  public void getFruitNotFound() {
    get("/fruits/XXXX").then()
        .statusCode(Status.NOT_FOUND.getStatusCode());
  }

  @Test
  @Order(DEFAULT_ORDER + 1)
  public void addFruit() {
    get("/fruits").then()
        .body("$.size()", is(10));

    given()
        .contentType(ContentType.JSON)
        .body("{\"name\":\"Another Lemon\",\"description\":\"Acidic fruit\"}")
        .when().post("/fruits")
        .then()
        .contentType(ContentType.JSON)
        .statusCode(Status.OK.getStatusCode())
        .body("id", greaterThanOrEqualTo(3))
        .body("name", is("Another Lemon"))
        .body("description", is("Acidic fruit"));

    get("/fruits").then()
        .body("$.size()", is(11));
  }
}
