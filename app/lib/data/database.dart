// ignore_for_file: recursive_getters
// (`check(kind.isIn(...))` es el idioma de Drift para restricciones de columna.)

import 'package:drift/drift.dart';

import '../core/ids.dart';
import '../features/transactions/transaction.dart';

part 'database.g.dart';

// Espejo de backend/supabase/migrations (0001 + 0002). Mismos nombres de tablas
// y columnas, ids UUID en texto, montos en centavos, `updated_at`/`deleted_at`
// para sincronizar. Si cambias algo aquí, cambia también la migración SQL.

@DataClassName('ProfileRow')
class Profiles extends Table {
  TextColumn get id => text()();
  TextColumn get displayName => text().nullable()();
  TextColumn get defaultCurrency => text().withDefault(const Constant('USD'))();
  DateTimeColumn get createdAt => dateTime().clientDefault(DateTime.now)();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('AccountRow')
class Accounts extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get name => text()();
  TextColumn get currency => text().withDefault(const Constant('USD'))();
  DateTimeColumn get createdAt => dateTime().clientDefault(DateTime.now)();
  DateTimeColumn get updatedAt => dateTime().clientDefault(DateTime.now)();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('CategoryRow')
class Categories extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get name => text()();
  TextColumn get kind => text().check(kind.isIn(['expense', 'income']))();
  TextColumn get icon => text().nullable()();
  TextColumn get color => text().nullable()();
  DateTimeColumn get updatedAt => dateTime().clientDefault(DateTime.now)();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('TxRow')
class Transactions extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get accountId => text().nullable()();
  TextColumn get categoryId => text().nullable()();
  IntColumn get amountCents => integer().check(amountCents.isBiggerOrEqualValue(0))();
  TextColumn get currency => text().withDefault(const Constant('USD'))();
  TextColumn get kind => text().check(kind.isIn(['expense', 'income']))();

  /// Día (`yyyy-MM-dd`), igual que `occurred_on date` en Postgres.
  TextColumn get occurredOn => text()();

  /// Instante exacto, para ordenar dentro del mismo día.
  DateTimeColumn get occurredAt => dateTime()();
  TextColumn get note => text().nullable()();
  TextColumn get recurrence => text().nullable()();
  DateTimeColumn get updatedAt => dateTime().clientDefault(DateTime.now)();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('BudgetRow')
class Budgets extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get categoryId => text().nullable()();

  /// Nulo = límite recurrente de cada mes (así funciona la app hoy).
  TextColumn get month => text().nullable()();
  IntColumn get limitCents => integer().check(limitCents.isBiggerOrEqualValue(0))();
  DateTimeColumn get updatedAt => dateTime().clientDefault(DateTime.now)();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('InvestmentRow')
class Investments extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get name => text()();
  TextColumn get assetType => text()();
  RealColumn get quantity => real().withDefault(const Constant(0))();
  IntColumn get costBasisCents => integer().withDefault(const Constant(0))();
  IntColumn get currentValueCents => integer().withDefault(const Constant(0))();
  TextColumn get currency => text().withDefault(const Constant('USD'))();
  DateTimeColumn get updatedAt => dateTime().clientDefault(DateTime.now)();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('GoalRow')
class Goals extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get name => text()();
  TextColumn get note => text().withDefault(const Constant(''))();
  IntColumn get targetCents => integer().check(targetCents.isBiggerOrEqualValue(0))();
  IntColumn get savedCents => integer().withDefault(const Constant(0))();
  TextColumn get iconKey => text().withDefault(const Constant('savings'))();
  IntColumn get colorIndex => integer().withDefault(const Constant(0))();
  TextColumn get currency => text().withDefault(const Constant('USD'))();
  DateTimeColumn get createdAt => dateTime().clientDefault(DateTime.now)();
  DateTimeColumn get updatedAt => dateTime().clientDefault(DateTime.now)();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('DebtRow')
class Debts extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();

  /// `owed_to_me` (me deben) o `i_owe` (debo).
  TextColumn get kind => text().check(kind.isIn(['owed_to_me', 'i_owe']))();
  TextColumn get person => text()();
  TextColumn get concept => text().withDefault(const Constant(''))();
  IntColumn get totalCents => integer().check(totalCents.isBiggerOrEqualValue(0))();
  IntColumn get paidCents => integer().withDefault(const Constant(0))();
  DateTimeColumn get dueDate => dateTime().nullable()();
  TextColumn get currency => text().withDefault(const Constant('USD'))();
  DateTimeColumn get createdAt => dateTime().clientDefault(DateTime.now)();
  DateTimeColumn get updatedAt => dateTime().clientDefault(DateTime.now)();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Tarjetas de crédito y débito (migración SQL 0003).
/// Crédito: `balance_cents` es lo usado del cupo. Débito: el saldo disponible.
@DataClassName('CardRow')
class Cards extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get name => text()();
  TextColumn get network => text()
      .withDefault(const Constant('other'))
      .check(network.isIn(['visa', 'mastercard', 'amex', 'diners', 'other']))();
  TextColumn get kind => text().check(kind.isIn(['credit', 'debit']))();
  TextColumn get last4 => text().nullable()();
  IntColumn get limitCents => integer().nullable()();
  IntColumn get balanceCents => integer().withDefault(const Constant(0))();
  IntColumn get cutDay => integer().nullable()();
  IntColumn get dueDay => integer().nullable()();
  IntColumn get colorIndex => integer().withDefault(const Constant(0))();
  TextColumn get currency => text().withDefault(const Constant('USD'))();
  DateTimeColumn get createdAt => dateTime().clientDefault(DateTime.now)();
  DateTimeColumn get updatedAt => dateTime().clientDefault(DateTime.now)();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Solo lectura en el cliente: la escribe el backend cuando exista.
@DataClassName('SubscriptionRow')
class Subscriptions extends Table {
  TextColumn get userId => text()();
  TextColumn get plan => text().withDefault(const Constant('premium'))();
  TextColumn get status => text().withDefault(const Constant('trialing'))();
  DateTimeColumn get trialEndsAt => dateTime()();
  DateTimeColumn get currentPeriodEnd => dateTime().nullable()();
  DateTimeColumn get graceUntil => dateTime().nullable()();
  DateTimeColumn get updatedAt => dateTime().clientDefault(DateTime.now)();

  @override
  Set<Column> get primaryKey => {userId};
}

@DataClassName('PaymentRow')
class Payments extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get provider => text().withDefault(const Constant('payphone'))();
  TextColumn get clientTransactionId => text().unique()();
  TextColumn get providerTransactionId => text().nullable().unique()();
  IntColumn get amountCents => integer()();
  TextColumn get currency => text().withDefault(const Constant('USD'))();
  TextColumn get status => text().withDefault(const Constant('pending'))();
  TextColumn get rawResponse => text().nullable()();
  DateTimeColumn get createdAt => dateTime().clientDefault(DateTime.now)();
  DateTimeColumn get verifiedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(tables: [
  Profiles,
  Accounts,
  Categories,
  Transactions,
  Budgets,
  Investments,
  Goals,
  Debts,
  Cards,
  Subscriptions,
  Payments,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          await customStatement(
            'CREATE INDEX transactions_user_day ON transactions (user_id, occurred_on DESC)',
          );
          await customStatement(
            'CREATE UNIQUE INDEX budgets_recurring_unique ON budgets (user_id, category_id) WHERE month IS NULL',
          );
          await _seed();
        },
        // Cada cambio de esquema futuro va aquí con su `from < N`, y el mismo
        // cambio se replica en una migración SQL de Supabase.
        onUpgrade: (m, from, to) async {
          if (from < 2) await m.createTable(cards);
        },
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );

  /// Perfil local, prueba gratis y categorías base.
  Future<void> _seed() async {
    final now = DateTime.now();
    await into(profiles).insert(
      ProfilesCompanion.insert(id: kLocalUserId, displayName: const Value('David')),
    );
    await into(subscriptions).insert(
      SubscriptionsCompanion.insert(
        userId: kLocalUserId,
        trialEndsAt: now.add(const Duration(days: 30)),
      ),
    );
    await batch((b) {
      for (final name in expenseCategories) {
        b.insert(categories, CategoriesCompanion.insert(
          id: newId(), userId: kLocalUserId, name: name, kind: TxKind.expense.name,
        ));
      }
      for (final name in incomeCategories) {
        b.insert(categories, CategoriesCompanion.insert(
          id: newId(), userId: kLocalUserId, name: name, kind: TxKind.income.name,
        ));
      }
    });
  }
}
